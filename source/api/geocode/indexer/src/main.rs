extern crate failure;
extern crate clap;
extern crate csv;
#[macro_use] extern crate serde_derive;
extern crate tantivy;

use failure::{
    Error,
    ResultExt
};
use clap::{App, Arg};
use tantivy::{
    Index,
    IndexWriter,
    schema::*
};
use std::fs::File;
use std::io::BufReader;
use std::path::Path;

#[derive(Debug, Deserialize)]
struct Record {
    name: String,
    alternative_names: Option<String>,
    osm_type: String,
    osm_id: u64,
    class: String,
    #[serde(rename = "type")]
    object_type: String,
    #[serde(rename = "lon")]
    longitude: f64,
    #[serde(rename = "lat")]
    latitude: f64,
    place_rank: Option<u64>,
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
    housenumbers: Option<String>
}

fn create_schema() -> Schema {
    let mut schema_builder = SchemaBuilder::default();

    schema_builder.add_text_field("name", TEXT | STORED);
    schema_builder.add_text_field("alternative_names", TEXT);
    schema_builder.add_text_field("longitude", STORED);
    schema_builder.add_text_field("latitude", STORED);

    schema_builder.build()
}

fn create_index(index_directory: &Path, schema: &Schema) -> Index {
    Index::create(index_directory, schema.clone()).unwrap()
}

fn index_record(index_writer: &mut IndexWriter, schema: &Schema, record: Record) -> tantivy::Result<()> {
    println!("~~> {:?}", record.name);

    let field_name = schema.get_field("name").unwrap();
    let field_alternative_names = schema.get_field("alternative_names").unwrap();
    let field_longitude = schema.get_field("longitude").unwrap();
    let field_latitude = schema.get_field("latitude").unwrap();

    let mut document = Document::default();
    document.add_text(field_name, &record.name);
    document.add_text(field_alternative_names, &record.alternative_names.unwrap_or("".into()));
    document.add_text(field_longitude, &record.longitude.to_string());
    document.add_text(field_latitude, &record.latitude.to_string());

    index_writer.add_document(document);

    Ok(())
}

fn main() -> Result<(), Error> {
    let matches =
        App::new("atlasr-api-geocode-indexer")
            .version(env!("CARGO_PKG_VERSION"))
            .about("Atlasr: Indexer for the geocode API.")
            .author("Ivan Enderlin")
            .arg(
                Arg::with_name("source-file")
                    .help("File containing the data to index, must be a `.tsv` file.")
                    .short("s")
                    .long("source-file")
                    .value_name("SOURCE_FILE")
                    .takes_value(true)
                    .required(true)
            )
            .arg(
                Arg::with_name("index-directory")
                    .help("Directory that will contain the index.")
                    .short("i")
                    .long("index-directory")
                    .value_name("INDEX_DIRECTORY")
                    .takes_value(true)
                    .required(true)
            )
            .get_matches();

    let source_file_name = matches.value_of("source-file").unwrap();
    let source_file = File::open(source_file_name).context("Cannot open the given file.")?;
    let source_buffer = BufReader::new(source_file);

    let mut source_reader =
        csv::ReaderBuilder::new()
            .delimiter(b'\t')
            .double_quote(false)
            .flexible(true)
            .from_reader(source_buffer);

    let index_directory = matches.value_of("index-directory").unwrap();
    let schema = create_schema();
    let index = create_index(Path::new(index_directory), &schema);
    let mut index_writer = index.writer(50_000_000)?;

    for record in source_reader.deserialize() {
        let record: Record = record?;

        index_record(&mut index_writer, &schema, record)?;
    }

    index_writer.commit()?;

    Ok(())
}
