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

		if ( directoryExists( rootDir & "/_site" ) ) directoryDelete( rootDir & "/_site", true );

		directoryCopy(
			rootDir & "/assets",
			rootDir & "/_site/assets",
			true
		);

		var conf = deserializeJSON( fileRead( rootDir & "/_data/jasperconfig.json", "utf-8" ) );

		print.yellowLine( "Building source directory: " & rootDir );

		var templateList = JasperService.list( rootDir );
		var collections  = { "all" : [], "tags" : [] };

		// build initial prc
		templateList.each( ( template ) => {
			var prc = {
				"rootDir"   : rootDir,
				"directory" : template.directory,
				"fileSlug"  : template.name.listFirst( "." ),
				"inFile"    : template.directory & "/" & template.name,
				"outFile"   : "",
				"headers"   : [],
				"meta"      : {
					"title"       : "",
					"description" : "",
					"author"      : "",
					"url"         : ""
				},
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

			// ensure the config does not mutate
			prc.append( duplicate( conf ) );

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
					prc.meta.title = prc.meta.title & " - " & prc.title;
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

		// build template list by type
		collections.all.each( ( template ) => {
			if ( !collections.keyExists( template.type ) ) collections[ template.type ] = [];
			collections[ lCase( template.type ) ].append( template )
		} );

		// descending date sort
		collections.post.sort( ( e1, e2 ) => {
			return dateCompare( e2.publishDate, e1.publishDate );
		} );

		// build tags
		collections[ "tags" ]  = [];
		collections[ "byTag" ] = {};

		collections.post.each( ( post ) => {
			for ( var tag in post.tags ) {
				if ( !collections.tags.find( tag ) ) {
					collections.tags.append( {
						"text" : tag,
						"slug" : JasperService.generateSlug( input = tag )
					} );
				}

				if ( !collections.byTag.keyExists( tag ) )
					collections.byTag[ JasperService.generateSlug( input = tag ) ] = [];
				collections.byTag[ JasperService.generateSlug( input = tag ) ].append( post );
			}
		} );

		// process pagination
		collections.all.each( ( prc ) => {
			if ( prc.keyExists( "pagination" ) ) {
				var data = prc.pagination.data.findNoCase( "collections." ) == 1 ? structGet( prc.pagination.data ) : structGet( "prc." & prc.pagination.data );

				prc[ "pagination" ][ "pagedData" ] = [];

				prc.pagination.pagedData.append(
					JasperService.paginate( data = data, pageSize = prc.pagination.size ),
					true
				);
			}
		} );

		// write the files
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
