extern crate failure;
extern crate clap;
extern crate csv;
#[macro_use] extern crate serde_derive;

use failure::{Error, ResultExt};
use clap::{App, Arg};
use std::fs::File;
use std::io::BufReader;

#[derive(Debug, Deserialize)]
struct Record {
    name: String,
    alternative_names: String,
    osm_type: String,
    osm_id: u64,
    class: String,
    #[serde(rename = "type")]
    object_type: String,
    #[serde(rename = "lon")]
    longitude: f64,
    #[serde(rename = "lat")]
    latitude: f64,
    place_rank: u64,
    importance: f64,
    street: Option<String>,
    city: Option<String>,
    county: Option<String>,
    state: Option<String>,
    country: Option<String>,
    country_code: Option<String>,
    display_name: String,
    #[serde(rename = "west")]
    bbox_west: f64,
    #[serde(rename = "south")]
    bbox_south: f64,
    #[serde(rename = "east")]
    bbox_east: f64,
    #[serde(rename = "north")]
    bbox_north: f64,
    wikidata: Option<String>,
    wikipedia: Option<String>,
    housenumbers: Option<u64>
}

fn main() -> Result<(), Error> {
    let matches =
        App::new("atlasr-api-geocode-indexer")
            .version(env!("CARGO_PKG_VERSION"))
            .about("Atlasr: Indexer for the geocode API.")
            .author("Ivan Enderlin")
            .arg(
                Arg::with_name("INPUT")
                    .help("Data to index, must be a `.tsv` file.")
                    .required(true)
                    .index(1)
            )
            .get_matches();

    let file_name = matches.value_of("INPUT").unwrap();
    let file = File::open(file_name).context("Cannot open the given file.")?;
    let buffer = BufReader::new(file);

    let mut csv_reader =
        csv::ReaderBuilder::new()
            .delimiter(b'\t')
            .double_quote(false)
            .flexible(true)
            .from_reader(buffer);

    for record in csv_reader.deserialize() {
        let record: Record = record?;

        println!("{:?}", record);
    }

    Ok(())
}
