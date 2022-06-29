component extends="commandbox.system.BaseCommand" {

	property name="YamlService" inject="Parser@cbyaml";

	function getFrontMatter( required string slug, required string fname ) {
		var data = {
			"slug"   : slug,
			"tags"   : [],
			"status" : "error"
		};

		if ( fileExists( fname ) ) {
			var openFile = fileOpen( fname, "read" );
			var lines    = [];
			try {
				while ( !fileIsEOF( openFile ) ) {
					arrayAppend( lines, fileReadLine( openFile ) );
				}
			} catch ( any e ) {
				rethrow;
			} finally {
				fileClose( openFile );
			}
			var fme  = lines.findAll( "---" )[ 2 ]; // front matter end
			var yaml = "";
			for ( var i = 2; i < fme; i++ ) {
				yaml &= lines[ i ] & chr( 10 );
			}
			data.append( YamlService.deserialize( yaml ) );
			data.status = lines.len() ? "ok" : "error";
		}

		return data;
	}

	function run() {
		var files = directoryList( "src/posts", false, "query" );

		files.each( ( file ) => {
			fileWrite(
				fileSystemUtil.resolvePath( "cache/" & file.name.listFirst( "." ) & "-fm.json" ),
				serializeJSON(
					getFrontMatter( slug = file.name.listFirst( "." ), fname = file.directory & "/" & file.name )
				)
			)
			print.line( "Writing frontmatter cache for: " & file.name.listFirst( "." ) );
		} )
	}

}
