use clap::{App, Arg};

fn main() {
    let matches = App::new("Halp")
        .version("0.2")
        .author("Leandro Motta Barros <lmb@stackedboxes.org>")
        .about("An Ad Hoc Literate Programming Tool")
        .arg(
            Arg::with_name("output-dir")
                .short("o")
                .long("output-dir")
                .alias("targetDir") // for backward compatibility
                .value_name("DIR")
                .default_value("generated_sources")
                .help("Sets the directory where the generated files will be written to")
                .takes_value(true),
        )
        .arg(
            Arg::with_name("INPUT")
                .help("The Halp source files to process")
                .required(true)
                .multiple(true)
                .index(1),
        )
        .get_matches();

    println!("Hello from Halp!");

    for input in matches.values_of("INPUT").unwrap() {
        println!("Input file: {}", input)
    }
}
