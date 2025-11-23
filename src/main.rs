use std::fs;

use crate::git_object::*;
use crate::index::*;

pub mod git_object;
pub mod index;

fn main() {
    let raw = fs::read("./.git/index").expect("could not read index");
    let i = Index::deserialize(raw);
    let i2 = Index::deserialize(i.serialize());
    let i3 = i2.serialize();
}
