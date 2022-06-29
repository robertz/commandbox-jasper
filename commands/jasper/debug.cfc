component extends="commandbox.system.BaseCommand" {

	property name="processor" inject="processor@commandbox-jasper";

	function getMarkdown( required string slug, required string fname ) {
		var data = {
			"slug"     : slug,
			"markdown" : "",
			"status"   : "error"
		};

		// file operation
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
			var fme = lines.findAll( "---" )[ 2 ]; // front matter end
			lines.each( ( line, row ) => {
				if ( row > fme ) data[ "markdown" ] &= line.len() ? ( line & chr( 10 ) ) : ( " " & chr( 10 ) );
			} );
			data.status = lines.len() ? "ok" : "error";
		}

		return data.markdown;
	}

	function run() {
		var markd = getMarkdown( "getting-started", "src/posts/getting-started.md" );
		fileWrite( "cache/getting-started.html", processor.toHTML( markd ) );
	}

}
