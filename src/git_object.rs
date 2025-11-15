// Implementation of Git objects, although I will avoid tags for now
use hex;
use sha1::{Digest, Sha1};

pub struct Blob {
    contents: String,
}

pub struct Tree {
    entries: Vec<TreeEntry>,
}

pub struct Commit {
    tree_hash: String,
    parents: Vec<String>,
    author: String,
    committer: String,
    message: String,
}

pub struct TreeEntry {
    pub mode: String,
    pub name: String,
    pub hash: Vec<u8>,
}

impl TreeEntry {
    fn of_blob(obj: GitObject, mode: &str, name: &str) -> Option<Self> {
        match obj {
            GitObject::Blob(_) => {
                let as_bin = obj.hash_bin();
                Some(TreeEntry {
                    mode: mode.to_owned(),
                    name: name.to_owned(),
                    hash: as_bin,
                })
            }
            _ => None,
        }
    }
}

pub enum GitObject {
    Blob(Blob),
    Tree(Tree),
    Commit(Commit), // Add tag later
}

impl From<&str> for GitObject {
    fn from(contents: &str) -> GitObject {
        GitObject::Blob(Blob {
            contents: contents.to_owned(),
        })
    }
}

impl From<Vec<TreeEntry>> for GitObject {
    fn from(entries: Vec<TreeEntry>) -> GitObject {
        GitObject::Tree(Tree { entries: entries })
    }
}

impl GitObject {
    pub fn hash_hex(&self) -> String {
        let mut hasher = Sha1::new();
        match self {
            GitObject::Blob(blob) => {
                let header = format!("blob {}\0", blob.contents.len());
                hasher.update(header.as_bytes());
                hasher.update(blob.contents.as_bytes());
                let digest = hasher.finalize();
                format!("{:x}", digest)
            }
            GitObject::Tree(tree) => {
                let mut contents: Vec<u8> = Vec::new();
                for entry in tree.entries.iter() {
                    contents.extend_from_slice(entry.mode.as_bytes());
                    contents.push(b' ');
                    contents.extend_from_slice(entry.name.as_bytes());
                    contents.push(0);
                    contents.extend_from_slice(entry.hash.as_slice());
                }

                let header = format!("tree {}\0", contents.len());
                hasher.update(header.as_bytes());
                hasher.update(contents);
                let digest = hasher.finalize();
                format!("{:x}", digest)
            }
            GitObject::Commit(commit) => {
                todo!()
            }
        }
    }

    pub fn hash_bin(&self) -> Vec<u8> {
        let as_hex = self.hash_hex();
        hex::decode(as_hex).expect("invalid hex?")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_blob_hash1() {
        let b = GitObject::from("test1\n");
        let hash = b.hash_hex();
        assert_eq!("a5bce3fd2565d8f458555a0c6f42d0504a848bd5", hash);
    }
    #[test]
    fn test_tree_hash1() {
        let b1 = GitObject::from("test1\n");
        let b2 = GitObject::from("test2\n");
        let t1 = GitObject::from(vec![
            TreeEntry::of_blob(b1, "100644", "b1.txt").unwrap(),
            TreeEntry::of_blob(b2, "100644", "b2.txt").unwrap(),
        ]);
        let hash = t1.hash_hex();
        assert_eq!("21a2e3a7b4f696d6ea5182d1b500571beebcf25a", hash);
    }
}
