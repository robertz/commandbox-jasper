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
				// core properties
				"title"                  : "",
				"description"            : "",
				"image"                  : "",
				"published"              : false,
				"publishDate"            : "",
				// other
				"content"                : "",
				"type"                   : "page",
				"layout"                 : "main",
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

			// handle facebook/twitter meta
			switch ( prc.type ) {
				case "post":
					prc.meta.title &= " - " & prc.title;
					// set social tags
					prc.headers.append( {
						"property" : "og:title",
						"content"  : "#prc.title#"
					} );
					prc.headers.append( {
						"property" : "og:description",
						"content"  : "#prc.description#"
					} );
					prc.headers.append( {
						"property" : "og:image",
						"content"  : "#prc.image#"
					} );
					prc.headers.append( {
						"name"    : "twitter:card",
						"content" : "summary_large_image"
					} );
					prc.headers.append( {
						"name"    : "twitter:title",
						"content" : "#prc.title#"
					} );
					prc.headers.append( {
						"name"    : "twitter:description",
						"content" : "#prc.description#"
					} );
					prc.headers.append( {
						"name"    : "twitter:image",
						"content" : "#prc.image#"
					} );
					break;
				default:
					break;
			};


			collections.all.append( prc );
		} ); // templateList each

		// build posts
		collections[ "posts" ] = collections.all.filter( ( post ) => {
			return post.type == "post"
		} );
		// descending date sort
		collections.posts.sort( ( e1, e2 ) => {
			return dateCompare( e2.publishDate, e1.publishDate );
		} );

		// build tags
		collections[ "tags" ] = [];
		collections.posts.each( ( post ) => {
			for ( var tag in post.tags ) if ( !collections.tags.find( tag ) ) collections.tags.append( tag );
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
		} ); // collections.all.each

		print.greenLine( "Compiled " & collections.all.len() & " template(s) in " & ( getTickCount() - startTime ) & "ms." )
	}

}
