component accessors="true" {

	property name="JasperService";
	property name="YamlService" inject="Parser@cbyaml";
	property name="processor"   inject="processor@commandbox-jasper";

	function init() {
		return this;
	}

	/**
	 *  Reads a template and returns front matter and template data
	 */
	function getTemplateData( required string fname ) {
		var payload  = {};
		var yaml     = "";
		var body     = "";
		var isCFM    = fname.findNoCase( ".cfm" ) ? true : false;
		var openFile = fileOpen( fname, "read" );
		var lines    = [];
		var payload  = {};

		try {
			while ( !fileIsEOF( openFile ) ) {
				arrayAppend( lines, fileReadLine( openFile ) );
			}
		} catch ( any e ) {
			rethrow;
		} finally {
			fileClose( openFile );
		}
		// front matter should be at the start of the file
		var fms = !isCFM ? lines.find( "---" ) : lines.find( "<!---" ); // front matter start

		if ( fms == 1 ) {
			var fme = !isCFM ? lines.findAll( "---" )[ 2 ] : lines.findAll( "--->" )[ 1 ]; // front matter end
			lines.each( ( line, index ) => {
				if ( index > 1 && index < fme ) yaml &= lines[ index ] & chr( 10 );
				if ( index > fme ) body &= lines[ index ] & chr( 10 );
			} );
			if ( yaml.len() ) payload.append( YamlService.deserialize( trim( yaml ) ) );
		} else {
			body = arrayToList( lines, chr( 10 ) );
		}
		payload[ "content" ] = processor.toHtml( body );

		return payload;
	}

	/**
	 * Build an array of posts for tag cloud
	 */
	function getTags( required array posts ) {
		var tags  = [];
		var posts = arguments.posts;
		// Calculate tags
		posts.each( function( post ) {
			for ( var tag in post.tags ) if ( !tags.find( tag ) ) tags.append( tag );
		} );
		return tags;
	}

	/**
	 * Get a list of valid templates in the specified file path, recursively
	 */
	function list( required string path ) {
		var templates = directoryList( path, true, "query", "*.md|*.cfm" );

		templates = queryExecute(
			"
				SELECT *
				FROM templates t
				WHERE lcase(t.directory) NOT LIKE '%_includes%'",
			[],
			{ "dbtype" : "query" }
		);
		return templates
	}

	/**
	 * Render a template
	 */
	function renderTemplate( required struct prc, required struct collections ) {
		var renderedHtml = "";
		var computedPath = prc.directory.replace( prc.rootDir, "" );
		// render the view based on prc.type
		if ( prc.inFile.findNoCase( ".cfm" ) ) {
			savecontent variable="renderedHtml" {
				include prc.directory & "/" & prc.fileSlug & ".cfm";
			}
		} else {
			savecontent variable="renderedHtml" {
				include prc.rootDir & "/_includes/" & prc.type & ".cfm";
			}
		}
		// skip layout if "none" is specified
		if ( prc.layout != "none" ) {
			savecontent variable="renderedHtml" {
				include prc.rootDir & "/_includes/layouts/" & prc.layout & ".cfm";
			}
		}
		// a little whitespace management
		return trim( renderedHtml );
	}

}
