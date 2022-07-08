component extends="commandbox.system.BaseCommand" {

	property name="JasperService" inject="JasperService@commandbox-jasper";

	function run() {
		var posts = [];
		var files = directoryList(
			fileSystemUtil.resolvePath( "posts" ),
			false,
			"query"
		);

		files.each( ( file ) => {
			var postData = JasperService.getPostData( fileSystemUtil.resolvePath( "posts/" & file.name ) );
			postData.delete( "html" );
			postData.delete( "content" );
			posts.append( postData );
		} );
		posts.sort( ( e1, e2 ) => {
			return dateCompare( e2.publishDate, e1.publishDate ); // desc
		} );

		print.line( "Writing post-cache.json" );
		fileWrite( fileSystemUtil.resolvePath( "_data/post-cache.json" ), serializeJSON( posts ) );
	}

}
