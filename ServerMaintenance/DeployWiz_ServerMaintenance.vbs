If Ucase(Property("ServerMaintenance")) = "YES" Then
	oEnvironment.Item("SkipTaskSequence") = "YES"
	oEnvironment.Item("SkipComputerName") = "YES"
	oEnvironment.Item("SkipDomainMembership") = "YES"
End if