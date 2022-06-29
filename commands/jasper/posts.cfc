component extends="commandbox.system.BaseCommand" {

	function run() {
		var files = directoryList(
			fileSystemUtil.resolvePath( "posts" ),
			false,
			"query"
		);
		print.line( files );
	}

}
