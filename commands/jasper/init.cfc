component {

	function run( string name = "My Jasper Project", boolean verbose = false ) {
		var pwd = fileSystemUtil.resolvePath( "." );

		var contents = directoryList( pwd, false, "name" );
		if ( contents.len() ) {
			return error( "Directory is not empty." );
		}

		command( "coldbox create app" )
			.params(
				name = arguments.name,
				skeleton = "robertz/jasper-cli",
				verbose = arguments.verbose
			)
			.run();

		print.greenLine( "Jasper project scaffolded." );
	}

}