component extends="commandbox.system.BaseCommand" {

	function run() {
		command( "server start" )
			.params(
				cfengine       = "none",
				rewritesEnable = "true",
				directory      = resolvePath( "_site" ),
				rewritesConfig = resolvePath( ".htaccess" ),
				port           = "8888"
			)
			.run();
	}

}
