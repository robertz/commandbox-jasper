component extends="commandbox.system.BaseCommand" {

	property name="processor"     inject="processor@commandbox-jasper";
	property name="JasperService" inject="JasperService@commandbox-jasper";

	function run() {
		var conf  = deserializeJSON( fileRead( fileSystemUtil.resolvePath( "jasperconfig.json" ), "utf-8" ) );
		var files = JasperService.list( path = fileSystemUtil.resolvePath( "src/posts" ) );
		files.each( ( file ) => {
			var html = "";
			var prc  = {
				"meta" : {},
				"post" : {},
				"html" : ""
			};
			prc.meta.append( conf.meta );
			prc.post.append(
				JasperService.getPostData( fname = fileSystemUtil.resolvePath( "src/posts/" & file.name ) )
			);
			savecontent variable="html" {
				include fileSystemUtil.resolvePath( "src/post.cfm" );
			}

			fileWrite( fileSystemUtil.resolvePath( "dist/post/" & prc.post.slug & ".html" ), html );
		} );
	}

	function run2() {
		var fn    = fileSystemUtil.resolvePath( "src/posts/getting-started.md" );
		var data  = JasperService.getPostData( fname = fn );
		data.body = processor.toHTML( data.body );

		print.line(
			command( "execute" )
				.params( file = "src/test.cfm", json = data.toJSON() )
				.overwrite( "dist/test.html" )
				.run( returnOutput = true )
		)
	}

}
