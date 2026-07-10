package harness

import "fmt"

func validateProducerDAG(dag producerDAG) error {
	nodes := make(map[string]producerNode, len(dag.Nodes))
	for _, node := range dag.Nodes {
		if _, found := nodes[node.ID]; found {
			return &HarnessError{"duplicate-producer", "producer ids must be unique"}
		}
		if _, err := stageRank(node.Stage); err != nil {
			return err
		}
		nodes[node.ID] = node
	}
	if dag.RootNode != "deployment_root_set" {
		return &HarnessError{"unresolved-producer", "deployment root producer is missing"}
	}
	if _, found := nodes[dag.RootNode]; !found {
		return &HarnessError{"unresolved-producer", "deployment root producer is missing"}
	}
	for _, node := range dag.Nodes {
		dependencies := map[string]bool{}
		for _, dependency := range node.Dependencies {
			if dependencies[dependency] {
				return &HarnessError{"duplicate-producer-dependency", node.ID + " repeats a dependency"}
			}
			dependencies[dependency] = true
		}
		for _, dependency := range node.Dependencies {
			if _, found := nodes[dependency]; !found {
				return &HarnessError{"unresolved-producer", fmt.Sprintf("%s depends on %s", node.ID, dependency)}
			}
		}
	}
	visiting := map[string]bool{}
	visited := map[string]bool{}
	var visit func(string) error
	visit = func(id string) error {
		if visited[id] {
			return nil
		}
		if visiting[id] {
			return &HarnessError{"producer-cycle", "cycle reaches " + id}
		}
		visiting[id] = true
		for _, dependency := range nodes[id].Dependencies {
			if err := visit(dependency); err != nil {
				return err
			}
		}
		delete(visiting, id)
		visited[id] = true
		return nil
	}
	for id := range nodes {
		if err := visit(id); err != nil {
			return err
		}
	}

	reachable := map[string]bool{}
	stack := []string{dag.RootNode}
	for len(stack) > 0 {
		id := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if reachable[id] {
			continue
		}
		reachable[id] = true
		stack = append(stack, nodes[id].Dependencies...)
	}
	for _, mapping := range dag.RootFieldProducers.entries() {
		node, found := nodes[mapping.producer]
		if !found {
			return &HarnessError{"unresolved-producer", fmt.Sprintf("root field %s maps to %s", mapping.field, mapping.producer)}
		}
		if node.Stage == "post-domain" {
			return &HarnessError{"post-domain-dependency", fmt.Sprintf("root field %s maps to %s", mapping.field, mapping.producer)}
		}
		if mapping.producer != mapping.expected || !reachable[mapping.producer] {
			return &HarnessError{"root-field-producer-mismatch", fmt.Sprintf("root field %s maps to %s, expected %s", mapping.field, mapping.producer, mapping.expected)}
		}
	}
	for id := range reachable {
		if nodes[id].Stage == "post-domain" {
			return &HarnessError{"post-domain-dependency", "deployment root reaches a post-domain producer"}
		}
	}
	for _, node := range dag.Nodes {
		nodeRank, _ := stageRank(node.Stage)
		for _, dependency := range node.Dependencies {
			dependencyRank, _ := stageRank(nodes[dependency].Stage)
			if dependencyRank >= nodeRank {
				return &HarnessError{"producer-non-forward-edge", fmt.Sprintf("%s depends on %s", node.ID, dependency)}
			}
		}
	}
	return nil
}

type rootFieldMapping struct {
	field, producer, expected string
}

func (fields rootFieldProducers) entries() []rootFieldMapping {
	return []rootFieldMapping{
		{"bridge_program_id", fields.BridgeProgramID, "bridge_program"},
		{"fresh_deployment_instance_id", fields.FreshDeploymentInstanceID, "deployment_instance"},
		{"source_identity_fingerprints", fields.SourceIdentityFingerprints, "source_fingerprints"},
		{"checkpoint_manifest_digests", fields.CheckpointManifestDigests, "checkpoint_manifests"},
		{"semantic_registry_template_root", fields.SemanticRegistryTemplateRoot, "semantic_registry_template"},
		{"artifact_template_root", fields.ArtifactTemplateRoot, "artifact_template"},
		{"destination_abi_template_digests", fields.DestinationABITemplateDigests, "destination_abi_templates"},
		{"deployment_recipe_digests", fields.DeploymentRecipeDigests, "deployment_recipes"},
		{"replay_policy_template_digest", fields.ReplayPolicyTemplateDigest, "replay_policy_template"},
		{"freshness_policy_template_digest", fields.FreshnessPolicyTemplateDigest, "freshness_policy_template"},
	}
}

func stageRank(stage string) (int, error) {
	switch stage {
	case "source":
		return 0, nil
	case "template":
		return 1, nil
	case "manifest":
		return 2, nil
	case "root-set":
		return 3, nil
	case "root-digest":
		return 4, nil
	case "domain":
		return 5, nil
	case "post-domain":
		return 6, nil
	default:
		return 0, &HarnessError{"producer-stage", stage}
	}
}
