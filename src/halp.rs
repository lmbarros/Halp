pub struct Block {
    pub file_name: String,
    pub name: String,
    pub contents: String,
}

pub fn read_blocks(file_name: &str) -> Vec<Block> {
    println!("Reding blocks from {}", file_name);

    Vec::new()
}
