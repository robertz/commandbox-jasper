component extends="commandbox.system.BaseCommand" {

	property name="JasperService" inject="JasperService@commandbox-jasper";

	function run() {
		command( "jasper cache build" ).run();

		directoryDelete( resolvePath( "_site" ), true );
		directoryCopy(
			resolvePath( "assets" ),
			resolvePath( "_site/assets" ),
			true
		);

		var conf  = deserializeJSON( fileRead( resolvePath( "_data/jasperconfig.json" ), "utf-8" ) );
		var posts = deserializeJSON( fileRead( resolvePath( "_data/post-cache.json" ), "utf-8" ) );
		var tags  = JasperService.getTags( posts );

		var rootDir = resolvePath( "." );
		rootDir     = left( rootDir, len( rootDir ) - 1 );

		// clear the template cache
		systemCacheClear();

		print.line( "Building source directory: " & rootDir );

		var templateList = JasperService.list( rootDir );

		print.line( templateList );

		templateList.each( ( template ) => {
			var prc = {
				"meta"     : {},
				"content"  : "",
				"tagCloud" : tags,
				"type"     : "page",
				"posts"    : posts
			};
			prc.append( conf );
			// Try reading the front matter from the template
			prc.append( JasperService.getPostData( fname = template.directory & "/" & template.name ) );
			// write the rendered HTML to disk

			var shortName = JasperService.writeTemplate(
				prc      = prc,
				template = template,
				rootDir  = rootDir
			);
			print.line( "Generating " & shortName );
		} );
	}

}
