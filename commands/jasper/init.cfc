component {

	function run( string name = "My Jasper Project", boolean verbose = false ) {
		var pwd = resolvePath( "." );

		var contents = directoryList( pwd, false, "name" );
		if ( contents.len() ) {
			return error( "Directory is not empty." );
		}
		print.yellowText( "Scaffolding project..." );

		command( "coldbox create app" )
			.params(
				name     = arguments.name,
				skeleton = "robertz/jasper-cli",
				verbose  = arguments.verbose
			)
			.run();

		var files = directoryList(
			path     = resolvePath( "jasper-cli" ),
			recurse  = true,
			listInfo = "query",
			type     = "file"
		);

		files.each( ( file ) => {
			directoryCreate(
				file.directory.replace( "/jasper-cli", "" ),
				true,
				true
			);
			fileWrite(
				file.directory.replace( "/jasper-cli", "" ) & "/" & file.name,
				fileRead( file.directory & "/" & file.name ),
				"utf-8"
			);
			print.line( "Writing " & file.directory.replace( "/jasper-cli", "" ) & "/" & file.name );
		} );

		directoryDelete( resolvePath( "jasper-cli" ), true );

		print.greenLine( "Jasper project scaffolded." );
	}

}