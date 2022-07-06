component extends="commandbox.system.BaseCommand" {

	property name="JasperService" inject="JasperService@commandbox-jasper";

	function run() {
		command( "jasper cache build" ).run();

		var conf  = deserializeJSON( fileRead( resolvePath( "_data/jasperconfig.json" ), "utf-8" ) );
		var posts = deserializeJSON( fileRead( resolvePath( "_data/post-cache.json" ), "utf-8" ) );
		var tags  = JasperService.getTags( posts );

		var rootDir = resolvePath( "." );
		rootDir     = left( rootDir, len( rootDir ) - 1 )

		print.line( "Building source directory: " & rootDir );

		var templateList = JasperService.list( rootDir );

		templateList.each( ( template ) => {
			var fragment     = "";
			var content      = "";
			var renderedHTML = "";
			var isCFM        = template.name.findNoCase( ".cfm" ) ? true : false;
			var prc          = {
				"meta"     : {},
				"content"  : "",
				"tagCloud" : tags,
				"type"     : "page",
				"posts"    : posts
			};

			prc.append( conf );
			// Try reading the front matter from the template
			prc.append( JasperService.getPostData( fname = template.directory & "/" & template.name ) );

			// render the view
			if ( prc.keyExists( "type" ) && prc.type == "page" ) {
				if ( isCFM ) {
					// we are rending a CFM file, just include it
					savecontent variable="fragment" {
						include resolvePath( template.directory & "/" & template.name );
					}
				} else {
					// use the page template
					savecontent variable="fragment" {
						include resolvePath( "_includes/page.cfm" );
					}
				}
			} else {
				// use the post template
				savecontent variable="fragment" {
					include resolvePath( "_includes/post.cfm" );
				}
			}

			// content is referenced in the layout
			content = fragment;

			// render the layout
			savecontent variable="fragment" {
				include resolvePath( "_includes/layouts/" & prc.layout & ".cfm" );
			}

			// renderedHTML is the combined view and layout
			renderedHTML = fragment;

			// write the rendered HTML to disk
			var computedPath = template.directory.replace( rootDir, "" );
			try {
				directoryCreate( resolvePath( "_site" & computedPath ) );
				print.line( "Creating " & resolvePath( "_site" & computedPath ) );
			} catch ( any e ) {
				// fail
			}
			if ( prc.keyExists( "type" ) && prc.type == "page" ) {
				fileWrite(
					resolvePath( "_site" & computedPath & "/" & listFirst( template.name, "." ) & ".html" ),
					renderedHTML
				);
				print.line( "_site" & computedPath & "/" & listFirst( template.name, "." ) & ".html" );
			} else {
				print.line( "_site" & computedPath & "/" & prc.slug & ".html" );
				fileWrite( resolvePath( "_site" & computedPath & "/" & prc.slug & ".html" ), renderedHTML );
			}
		} );
	}

}
