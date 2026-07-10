use serde_json::Value as JsonValue;

use crate::HarnessError;

#[derive(Debug, Clone)]
pub enum Value {
    Unsigned(u64),
    Bytes(Vec<u8>),
    Text(String),
    Array(Vec<Value>),
    Map(Vec<(String, Value)>),
    Bool(bool),
}

pub fn encode_json(value: &JsonValue) -> Result<Vec<u8>, HarnessError> {
    encode(&from_json(value)?)
}

pub fn encode(value: &Value) -> Result<Vec<u8>, HarnessError> {
    match value {
        Value::Unsigned(value) => Ok(encode_head(0, *value)),
        Value::Bytes(value) => {
            let mut out = encode_head(2, value.len() as u64);
            out.extend_from_slice(value);
            Ok(out)
        }
        Value::Text(value) => {
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
        Value::Map(values) => {
            let mut entries = values
                .iter()
                .map(|(key, value)| {
                    let key = encode(&Value::Text(key.clone()))?;
                    let value = encode(value)?;
                    Ok((key, value))
                })
                .collect::<Result<Vec<_>, HarnessError>>()?;
            entries.sort_by(|left, right| left.0.cmp(&right.0));
            let mut out = encode_head(5, entries.len() as u64);
            for (key, value) in entries {
                out.extend(key);
                out.extend(value);
            }
            Ok(out)
        }
        Value::Bool(false) => Ok(vec![0xf4]),
        Value::Bool(true) => Ok(vec![0xf5]),
    }
}

fn from_json(value: &JsonValue) -> Result<Value, HarnessError> {
    match value {
        JsonValue::Number(number) => number.as_u64().map(Value::Unsigned).ok_or_else(|| {
            HarnessError::new(
                "unsupported-cbor-value",
                "only unsigned integers are supported",
            )
        }),
        JsonValue::String(value) => Ok(Value::Text(value.clone())),
        JsonValue::Array(values) => values
            .iter()
            .map(from_json)
            .collect::<Result<Vec<_>, _>>()
            .map(Value::Array),
        JsonValue::Object(values) => values
            .iter()
            .map(|(key, value)| Ok((key.clone(), from_json(value)?)))
            .collect::<Result<Vec<_>, _>>()
            .map(Value::Map),
        JsonValue::Bool(value) => Ok(Value::Bool(*value)),
        JsonValue::Null => Err(HarnessError::new(
            "unsupported-cbor-value",
            "null is outside the structural profile",
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
