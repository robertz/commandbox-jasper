component {

	property name="YamlService" inject="Parser@cbyaml";
	property name="processor"   inject="processor@commandbox-jasper";

	function init() {
		return this;
	}

	function getPostData( required string fname ) {
		var payload = {};
		var yaml    = "";
		var body    = "";

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
		lines.each( ( line, index ) => {
			if ( index > 1 && index < fme ) yaml &= lines[ index ] & chr( 10 );
			if ( index > fme ) body &= lines[ index ] & chr( 10 );
		} )
		var frontMatter = YamlService.deserialize( trim( yaml ) );

		var payload = { "html" : processor.toHtml( body ) };
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
		return directoryList( path, false, "query" )
	}

}
