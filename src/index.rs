// Git index (staging area) using Version 2 format
// Needs better error handling

use core::panic;
use sha1::{Digest, Sha1};
use std::convert::TryInto;
use std::fs::{self, read};

pub struct Index {
    // Signature always { 'D', 'I', 'R', 'C' } (4-bytes)
    // For now, version always 2 (4-bytes)
    entries: Vec<Entry>,
    // No extensions currently
    checksum: [u8; 20],
}

#[derive(Debug)]
struct Entry {
    ctime_sec: [u8; 4],
    ctime_nsec: [u8; 4],
    mtime_sec: [u8; 4],
    mtime_nsec: [u8; 4],
    dev: [u8; 4],
    ino: [u8; 4],
    mode: [u8; 4],
    uid: [u8; 4],
    gid: [u8; 4],
    size: [u8; 4],
    sha1: [u8; 20],
    flags: [u8; 2],
    file_path: Vec<u8>,
    padding: Vec<u8>, // Pad for byte align
}

impl Index {
    pub fn deserialize(index: Vec<u8>) -> Self {
        // Add checksum verification
        match index.get(0..4) {
            Some(sig) => {
                if sig != [68, 73, 82, 67] {
                    panic!("malformed index")
                }
            }
            None => panic!("no index?"),
        }
        match index.get(4..8) {
            Some(version) => {
                if version != [0, 0, 0, 2] {
                    panic!("unsupported Git version")
                }
            }
            None => panic!("no version?"),
        }
        let entry_amt = match index.get(8..12) {
            Some(amt) => u32::from_be_bytes(amt.try_into().unwrap()),
            None => panic!("no entry amount"),
        };
        let mut entries: Vec<Entry> = Vec::new();
        let mut remainder: &[u8] = match index.get(12..) {
            Some(r) => r,
            None => panic!("incomplete index"),
        };
        for _ in 1..=entry_amt {
            let entry = get_entry(remainder);
            entries.push(entry.0);
            remainder = entry.1;
        }

        let checksum = match remainder.get(remainder.len() - 20..) {
            Some(c) => c,
            None => panic!("no idea what just happened"),
        };

        return Index {
            entries: entries,
            checksum: checksum.try_into().unwrap(),
        };
    }

    pub fn serialize(self) -> Vec<u8> {
        let mut raw: Vec<u8> = Vec::new();

        let tag = [b'D', b'I', b'R', b'C'];
        let version: [u8; 4] = [0, 0, 0, 2];

        raw.extend_from_slice(&tag);
        raw.extend_from_slice(&version);
        let ec: u32 = u32::try_from(self.entries.len()).expect("too many entries??");
        let entry_amt = ec.to_be_bytes();
        raw.extend_from_slice(&entry_amt);

        for e in self.entries {
            raw.extend_from_slice(&e.ctime_sec);
            raw.extend_from_slice(&e.ctime_nsec);
            raw.extend_from_slice(&e.mtime_sec);
            raw.extend_from_slice(&e.mtime_nsec);
            raw.extend_from_slice(&e.dev);
            raw.extend_from_slice(&e.ino);
            raw.extend_from_slice(&e.mode);
            raw.extend_from_slice(&e.uid);
            raw.extend_from_slice(&e.gid);
            raw.extend_from_slice(&e.size);
            raw.extend_from_slice(&e.sha1);
            raw.extend_from_slice(&e.flags);
            raw.extend_from_slice(&e.file_path);
            raw.extend_from_slice(&e.padding);
        }

        let mut hasher = Sha1::new();
        hasher.update(&raw);
        let new_checksum = hasher.finalize();

        raw.extend_from_slice(&new_checksum);
        return raw;
    }
}

fn read_u32(bytes: &[u8], offset: usize) -> [u8; 4] {
    bytes[offset..offset + 4].try_into().unwrap()
}

fn get_entry<'a>(bytes: &'a [u8]) -> (Entry, &'a [u8]) {
    let mut entry: Entry = match bytes.get(0..62) {
        Some(contents) => Entry {
            ctime_sec: read_u32(contents, 0),
            ctime_nsec: read_u32(contents, 4),
            mtime_sec: read_u32(contents, 8),
            mtime_nsec: read_u32(contents, 12),
            dev: read_u32(contents, 16),
            ino: read_u32(contents, 20),
            mode: read_u32(contents, 24),
            uid: read_u32(contents, 28),
            gid: read_u32(contents, 32),
            size: read_u32(contents, 36),
            sha1: contents[40..60].try_into().unwrap(),
            flags: contents[60..62].try_into().unwrap(),
            file_path: Vec::new(),
            padding: Vec::new(),
        },
        None => panic!("problem with an index entry"),
    };
    let name_len = (u16::from_be_bytes(entry.flags) & 0x0fff) as usize;
    let name_end = 62 + name_len;
    entry.file_path.extend_from_slice(&bytes[62..name_end]);
    let padding_len = match (8 - (name_end % 8)) % 8 {
        0 => 8,
        x => x,
    };
    entry
        .padding
        .extend_from_slice(&bytes[name_end..name_end + padding_len]);
    let next = name_end + padding_len;
    return (entry, &bytes[next..]);
}

#[cfg(test)]
mod tests {
    use super::*;
}
