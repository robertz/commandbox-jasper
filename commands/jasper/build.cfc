component extends="commandbox.system.BaseCommand" {

	property name="processor"     inject="processor@commandbox-jasper";
	property name="JasperService" inject="JasperService@commandbox-jasper";

	function run() {
		command( "jasper cache build" ).run();

		var conf  = deserializeJSON( fileRead( fileSystemUtil.resolvePath( "jasperconfig.json" ), "utf-8" ) );
		var posts = deserializeJSON( fileRead( fileSystemUtil.resolvePath( "post-cache.json" ), "utf-8" ) );
		var tags  = JasperService.getTags( posts );

		var html = "";
		var prc  = {
			"meta"     : {},
			"posts"    : posts,
			"html"     : "",
			"tagCloud" : JasperService.getTags( posts )
		};
		prc.meta.append( conf.meta );
		// get the home page
		savecontent variable="html" {
			include fileSystemUtil.resolvePath( "src/index.cfm" );
		}

		fileWrite( fileSystemUtil.resolvePath( "dist/index.html" ), html );

		// Build all posts
		var files = JasperService.list( path = fileSystemUtil.resolvePath( "src/posts" ) );
		files.each( ( file ) => {
			print.line( "Generating file for: " & file.name );

			var html = "";
			var prc  = {
				"meta"     : {},
				"post"     : {},
				"html"     : "",
				"tagCloud" : tags
			};
			prc.meta.append( conf.meta );
			prc.post.append(
				JasperService.getPostData( fname = fileSystemUtil.resolvePath( "src/posts/" & file.name ) )
			);

			prc.meta.title &= " - " & prc.post.title;

			savecontent variable="html" {
				include fileSystemUtil.resolvePath( "src/post.cfm" );
			}

			fileWrite( fileSystemUtil.resolvePath( "dist/post/" & prc.post.slug & ".html" ), html );

			// build tags
		} );

		tags.each( ( tag ) => {
			print.line( "Generating... dist/tag/" & tag.replace( " ", "-", "all" ) & ".html" );

			var html = "";
			var prc  = {
				"meta"     : {},
				"tag"      : tag,
				"posts"    : [],
				"html"     : "",
				"tagCloud" : tags
			};
			prc.meta.append( conf.meta );

			prc.posts = posts.filter( ( post ) => {
				return post.tags.findNoCase( prc.tag );
			} );

			prc.meta.title &= " - " & prc.tag;

			savecontent variable="html" {
				include fileSystemUtil.resolvePath( "src/tags.cfm" );
			}

			fileWrite( fileSystemUtil.resolvePath( "dist/tag/" & tag.replace( " ", "-", "all" ) & ".html" ), html );
		} )
	}

}
