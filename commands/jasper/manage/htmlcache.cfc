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
		var files = directoryList( "src/posts", false, "query" );

		files.each( ( file ) => {
			fileWrite(
				"cache/" & file.name.listFirst( "." ) & ".html",
				processor.toHTML(
					getMarkdown( slug = file.name.listFirst( "." ), fname = file.directory & "/" & file.name )
				)
			);
			print.line( "... writing html cache for " & file.name.listFirst( "." ) )
		} );
	}

}
