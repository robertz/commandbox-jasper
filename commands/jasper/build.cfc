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

			var prc = {
				"meta"     : {},
				"content"  : "",
				"tagCloud" : tags,
				"type"     : "page"
			};

			prc.append( conf );
			prc.append( JasperService.getPostData( fname = template.directory & "/" & template.name ) );

			if ( prc.keyExists( "type" ) && prc.type == "page" ) {
				savecontent variable="fragment" {
					include resolvePath( template.directory & "/" & template.name );
				}
			} else {
				savecontent variable="fragment" {
					include resolvePath( "_includes/post.cfm" );
				}
			}

			content = fragment;

			// render the layout
			savecontent variable="fragment" {
				include resolvePath( "_includes/layouts/" & prc.layout & ".cfm" );
			}

			renderedHTML = fragment;

			var computedPath = template.directory.replace( rootDir, "" );

			if ( prc.keyExists( "type" ) && prc.type == "page" ) {
				print.line( "_site/" & computedPath & listFirst( template.name, "." ) & ".html" );
				fileWrite(
					resolvePath( "_site/" & computedPath & listFirst( template.name, "." ) & ".html" ),
					renderedHTML
				);
			} else {
				print.line( "_site" & computedPath & "/" & prc.slug & ".html" );
				fileWrite( resolvePath( "_site" & computedPath & "/" & prc.slug & ".html" ), renderedHTML );
			}
		} );
	}

}
