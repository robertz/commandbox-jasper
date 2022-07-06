component accessors="true" singleton {

	property name="JasperService";
	property name="YamlService" inject="Parser@cbyaml";
	property name="processor"   inject="processor@commandbox-jasper";

	function init() {
		return this;
	}

	function getPostData( required string fname ) {
		var payload  = {};
		var yaml     = "";
		var body     = "";
		var isCFM    = fname.findNoCase( ".cfm" ) ? true : false;
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
		var fme = !isCFM ? lines.findAll( "---" )[ 2 ] : lines.findAll( "--->" )[ 1 ]; // front matter end
		lines.each( ( line, index ) => {
			if ( index > 1 && index < fme ) yaml &= lines[ index ] & chr( 10 );
			if ( index > fme ) body &= lines[ index ] & chr( 10 );
		} )
		var frontMatter = YamlService.deserialize( trim( yaml ) );

		var payload = { "content" : processor.toHtml( body ) };
		payload.append( frontMatter );

		return payload;
	}


	function getTags( required array posts ) {
		var tags  = [];
		var posts = arguments.posts;
		// Calculate tags
		posts.each( function( post ) {
			for ( var tag in post.tags ) if ( !tags.find( tag ) ) tags.append( tag );
		} );
		return tags;
	}

	function list( required string path ) {
		var templates = directoryList( path, true, "query", "*.md|*.cfm" );
		templates     = queryExecute(
			"
			SELECT * FROM templates t
			WHERE t.directory NOT LIKE '%_includes%' AND t.directory NOT LIKE '%_site%'",
			[],
			{ "dbtype" : "query" }
		);
		return templates;
	}

}
