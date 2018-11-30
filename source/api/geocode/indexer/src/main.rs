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
    directory,
    schema::*
};
use std::fs::File;
use std::io::{
    self,
    BufReader,
    Write
};

/// [Definition of these fields](http://osmnames.readthedocs.io/en/latest/introduction.html#output-format).
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
    longitude: Option<f64>,
    #[serde(rename = "lat")]
    latitude: Option<f64>,
    place_rank: Option<u64>,
    importance: Option<f64>,
    street: Option<String>,
    city: Option<String>,
    county: Option<String>,
    state: Option<String>,
    country: Option<String>,
    country_code: Option<String>,
    display_name: String,
    #[serde(rename = "west")]
    bbox_west: Option<f64>,
    #[serde(rename = "south")]
    bbox_south: Option<f64>,
    #[serde(rename = "east")]
    bbox_east: Option<f64>,
    #[serde(rename = "north")]
    bbox_north: Option<f64>,
    wikidata: Option<String>,
    wikipedia: Option<String>,
    housenumbers: Option<String>
}

impl Record {
    fn indexable(&self) -> bool {
        if self.longitude.is_none() || self.latitude.is_none() {
            return false;
        }

        match (self.class.as_str(), self.object_type.as_str()) {
            ("boundary", _) |
            ("highway", "residential") => {
                return true;
            },

            (_, _) => { }
        }

        false
    }
}

fn create_schema() -> Schema {
    let mut schema_builder = SchemaBuilder::default();

    schema_builder.add_text_field("display_name", TEXT | STORED);
    schema_builder.add_text_field("class", STORED);
    schema_builder.add_text_field("type", STORED);
    schema_builder.add_text_field("longitude", STORED);
    schema_builder.add_text_field("latitude", STORED);

    schema_builder.build()
}

fn create_index(index_directory: directory::MmapDirectory, schema: &Schema) -> Index {
    Index::create(index_directory, schema.clone()).unwrap()
}

fn index_record(index_writer: &mut IndexWriter, schema: &Schema, record: Record) -> tantivy::Result<()> {
    if ! record.indexable() {
        return Ok(());
    }

    let field_display_name = schema.get_field("display_name").unwrap();
    let field_class = schema.get_field("class").unwrap();
    let field_type = schema.get_field("type").unwrap();
    let field_longitude = schema.get_field("longitude").unwrap();
    let field_latitude = schema.get_field("latitude").unwrap();

    let mut document = Document::default();
    document.add_text(field_display_name, &record.display_name);
    document.add_text(field_class, &record.class);
    document.add_text(field_type, &record.object_type);
    document.add_text(field_longitude, &record.longitude.unwrap().to_string());
    document.add_text(field_latitude, &record.latitude.unwrap().to_string());

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
    let index = create_index(directory::MmapDirectory::open(index_directory)?, &schema);
    let mut index_writer = index.writer(50_000_000)?;
    let stdout = io::stdout();
    let mut handle = stdout.lock();

    for record in source_reader.deserialize() {
        let record: Record = record?;

        handle.write(b"~~> ").unwrap();
        handle.write(record.name.as_bytes()).unwrap();
        handle.write(b"\n").unwrap();

        index_record(&mut index_writer, &schema, record)?;
    }

    index_writer.commit()?;

    Ok(())
}
