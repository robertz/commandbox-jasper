component accessors="true" {

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

	function writeTemplate(
		required struct prc,
		required struct template,
		required string rootDir
	) {
		var renderedHtml = "";
		var computedPath = template.directory.replace( rootDir, "" );

		directoryCreate(
			rootDir & "/_site/" & computedPath,
			true,
			true
		);

		// render the view
		switch ( lCase( prc.type ) ) {
			case "post":
				savecontent variable="renderedHtml" {
					include rootDir & "/_includes/post.cfm";
				}
				break;
			default:
				// page
				if ( template.name.findNoCase( ".cfm" ) ) {
					// we are rending a CFM file, just include it
					savecontent variable="renderedHtml" {
						include template.directory & "/" & template.name;
					}
				} else {
					// use the page template
					savecontent variable="renderedHtml" {
						include rootDir & "/_includes/page.cfm";
					}
				}
				break;
		}
		var renderedHtml = "";

		// render the view
		switch ( lCase( prc.type ) ) {
			case "post":
				savecontent variable="renderedHtml" {
					include rootDir & "/_includes/post.cfm";
				}
				break;
			default:
				// page
				if ( template.name.findNoCase( ".cfm" ) ) {
					// we are rending a CFM file, just include it
					savecontent variable="renderedHtml" {
						include template.directory & "/" & template.name;
					}
				} else {
					// use the page template
					savecontent variable="renderedHtml" {
						include rootDir & "/_includes/page.cfm";
					}
				}
				break;
		}

		savecontent variable="renderedHtml" {
			include rootDir & "/_includes/layouts/" & prc.layout & ".cfm";
		}

		var fname     = "";
		var shortName = "";
		switch ( lCase( prc.type ) ) {
			case "post":
				shortName = computedPath & "/" & prc.slug & ".html";
				break;
			default:
				shortName = computedPath & "/" & listFirst( template.name, "." ) & ".html";
				break;
		}
		fname = rootDir & "/_site/" & shortName;

		fileWrite( fname, renderedHtml );

		return shortName;
	}

}
