// Git index (staging area) using Version 2 format

use std::fs;

struct Index {
    // Signature always { 'D', 'I', 'R', 'C' } (4-bytes)
    // For now, version always 2 (4-bytes)
    num_entries: [u8; 4],
    entries: Vec<Entry>,
    // No extensions currently
    checksum: [u8; 20],
}

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
  let index = fs::read("./.git/index");
}