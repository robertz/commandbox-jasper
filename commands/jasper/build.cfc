component extends="commandbox.system.BaseCommand" {

	property name="JasperService" inject="JasperService@commandbox-jasper";

	function getOutfile( required struct prc ) {
		var outFile = "";
		if ( prc.type == "page" ) {
			outFile = prc.inFile.replace( prc.rootDir, "" ).listFirst( "." );
			outFile = prc.rootDir & "/_site" & outFile & "." & prc.fileExt
		} else {
			outFile   = prc.inFile.replace( prc.rootDir, "" );
			var temp  = outFile.listToArray( "/" ).reverse();
			temp[ 1 ] = prc.slug & "." & prc.fileExt;
			outFile   = prc.rootDir & "/_site/" & temp.reverse().toList( "/" );
		}
		return outfile;
	}

	function run() {
		var startTime = getTickCount();
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
		var collections  = { "all" : [] };

		templateList.each( ( template ) => {
			var prc = {
				"rootDir"                : rootDir,
				"directory"              : template.directory,
				"fileSlug"               : template.name.listFirst( "." ),
				"inFile"                 : template.directory & "/" & template.name,
				"outFile"                : "",
				"headers"                : [],
				"meta"                   : {},
				"content"                : "",
				"tagCloud"               : tags,
				"type"                   : "page",
				"layout"                 : "main",
				"posts"                  : posts,
				"permalink"              : true,
				"fileExt"                : "html",
				"excludeFromCollections" : false
			};
			prc.append( conf );
			// Try reading the front matter from the template
			prc.append( JasperService.getTemplateData( fname = template.directory & "/" & template.name ) );

			prc[ "outFile" ] = getOutfile( prc = prc );

			if ( !isBoolean( prc.permalink ) ) {
				prc.outFile = rootDir & prc.permalink

				var temp = prc.permalink.listToArray( "/" ).reverse();
				var slug = temp[ 1 ].listFirst( "." );
				var ext  = temp[ 1 ].listRest( "." );

				prc.permalink = "/" & temp.reverse().toList( "/" );
				prc.fileExt   = len( ext ) ? ext : "html";
			}

			collections.all.append( prc );
		} );

		collections.all.each( ( prc ) => {
			var computedPath = prc.directory.replace( prc.rootDir, "" );

			var fname     = "";
			var shortName = "";

			if ( lCase( prc.type ) == "post" ) {
				shortName = computedPath & "/" & prc.slug & "." & prc.fileExt;
			} else {
				shortName = computedPath & "/" & prc.fileSlug & "." & prc.fileExt;
			}

			fname = prc.rootDir & "/_site/" & shortName;
			directoryCreate(
				prc.rootDir & "/_site/" & computedPath,
				true,
				true
			);
			fileWrite( fname, JasperService.renderTemplate( prc = prc, collections = collections ) );
		} );
		print.greenLine( "Compiled " & collections.all.len() & " template(s) in " & ( getTickCount() - startTime ) & "ms." )
	}

}
