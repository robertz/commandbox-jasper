component extends="commandbox.system.BaseCommand" {

	property name="JasperService" inject="JasperService@commandbox-jasper";

	function run() {
		// clear the template cache
		systemCacheClear();
		var rootDir = resolvePath( "." );
		rootDir     = left( rootDir, len( rootDir ) - 1 ); // remove trailing slash to match directoryList query

		command( "jasper cache build" ).run();

		if ( directoryExists( rootDir & "/_site" ) ) directoryDelete( rootDir & "/_site", true );

		directoryCopy(
			rootDir & "/assets",
			rootDir & "/_site/assets",
			true
		);

		var conf  = deserializeJSON( fileRead( rootDir & "/_data/jasperconfig.json", "utf-8" ) );
		var posts = deserializeJSON( fileRead( rootDir & "/_data/post-cache.json", "utf-8" ) );
		var tags  = JasperService.getTags( posts );

		print.yellowLine( "Building source directory: " & rootDir );

		var templateList = JasperService.list( rootDir );

		templateList.each( ( template ) => {
			var prc = {
				"rootDir"   : rootDir,
				"directory" : template.directory,
				"file"      : template.name,
				"meta"      : {},
				"content"   : "",
				"tagCloud"  : tags,
				"type"      : "page",
				"layout"    : "main",
				"posts"     : posts
			};
			prc.append( conf );
			// Try reading the front matter from the template
			prc.append( JasperService.getPostData( fname = template.directory & "/" & template.name ) );
			// write the rendered HTML to disk

			var shortName = JasperService.writeTemplate( prc = prc );
			print.greenLine( "Generating " & shortName );
		} );
	}

}
