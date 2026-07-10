use serde_json::Value;

use crate::HarnessError;

pub fn encode(value: &Value) -> Result<Vec<u8>, HarnessError> {
    match value {
        Value::Number(number) => number
            .as_u64()
            .map(|value| encode_head(0, value))
            .ok_or_else(|| HarnessError::new("unsupported-cbor-value", "only unsigned integers are supported")),
        Value::String(value) => {
            let bytes = value.as_bytes();
            let mut out = encode_head(3, bytes.len() as u64);
            out.extend_from_slice(bytes);
            Ok(out)
        }
        Value::Array(values) => {
            let mut out = encode_head(4, values.len() as u64);
            for value in values {
                out.extend(encode(value)?);
            }
            Ok(out)
        }
        Value::Object(values) => {
            let mut entries = values
                .iter()
                .map(|(key, value)| {
                    let key = encode(&Value::String(key.clone()))?;
                    let value = encode(value)?;
                    Ok((key, value))
                })
                .collect::<Result<Vec<_>, HarnessError>>()?;
            entries.sort_by(|left, right| {
                left.0
                    .len()
                    .cmp(&right.0.len())
                    .then_with(|| left.0.cmp(&right.0))
            });
            let mut out = encode_head(5, entries.len() as u64);
            for (key, value) in entries {
                out.extend(key);
                out.extend(value);
            }
            Ok(out)
        }
        _ => Err(HarnessError::new(
            "unsupported-cbor-value",
            "booleans, null, bytes, negative integers, and floats are outside the structural profile",
        )),
    }
}

fn encode_head(major: u8, value: u64) -> Vec<u8> {
    let prefix = major << 5;
    match value {
        0..=23 => vec![prefix | value as u8],
        24..=0xff => vec![prefix | 24, value as u8],
        0x100..=0xffff => {
            let mut out = vec![prefix | 25];
            out.extend_from_slice(&(value as u16).to_be_bytes());
            out
        }
        0x1_0000..=0xffff_ffff => {
            let mut out = vec![prefix | 26];
            out.extend_from_slice(&(value as u32).to_be_bytes());
            out
        }
        _ => {
            let mut out = vec![prefix | 27];
            out.extend_from_slice(&value.to_be_bytes());
            out
        }
    }
}
