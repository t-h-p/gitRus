// Git index (staging area) using Version 2 format

use std::convert::TryInto;
use std::fs::{self, read};

struct Index {
    // Signature always { 'D', 'I', 'R', 'C' } (4-bytes)
    // For now, version always 2 (4-bytes)
    num_entries: [u8; 4],
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

pub fn parse_index() {
    let index = fs::read("./.git/index").unwrap();
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
    let e1 = get_entry(index.get(12..).unwrap());
    print!("{:?}",String::from_utf8(e1.0.file_path).unwrap());
}

fn read_u32(bytes: &[u8], offset: usize) -> [u8; 4] {
    bytes[offset..offset+4].try_into().unwrap()
}

fn get_entry(bytes: &[u8]) -> (Entry, Vec<u8>) {
    let mut entry: Entry = match bytes.get(0..62) {
        Some(contents) => Entry {
            ctime_sec: read_u32(contents,0),
            ctime_nsec: read_u32(contents,4),
            mtime_sec: read_u32(contents,8),
            mtime_nsec: read_u32(contents,12),
            dev: read_u32(contents,16),
            ino: read_u32(contents,20),
            mode: read_u32(contents,24),
            uid: read_u32(contents,28),
            gid: read_u32(contents, 32),
            size: read_u32(contents, 36),
            sha1: contents[40..60].try_into().unwrap(),
            flags: contents[60..62].try_into().unwrap(),
            file_path: Vec::new(),
            padding: Vec::new(),
        },
        None => panic!("problem with an index entry"),
    };
    // name length encoded in lower 12 bits of flags
    let name_len = (u16::from_be_bytes(entry.flags) & 0x0fff) as usize;
    let name_end = 62 + name_len;
    entry.file_path.extend_from_slice(&bytes[62..name_end]);
    // calculate padding to 8-byte alignment
    let padding_len = (8 - (name_end % 8)) % 8;
    entry
        .padding
        .extend_from_slice(&bytes[name_end..name_end + padding_len]);
    let next = name_end + padding_len;
    return (entry, bytes[next..].to_vec());
}

#[cfg(test)]
mod tests {
    use super::*;
}
