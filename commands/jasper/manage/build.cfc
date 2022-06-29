component extends="commandbox.system.BaseCommand" {

	function run() {
		var files = directoryList(
			fileSystemUtil.resolvePath( "_src/posts" ),
			false,
			"query"
		);

		// build index
		print.line( "... building index" );
		command( "execute src/index.cfm > dist/index.html" );

		print.line( "Build complete." );
	}

}
