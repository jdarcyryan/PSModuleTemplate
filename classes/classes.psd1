@{
    classes = @(
        # Compiled classes (C# and VB.NET) should be loaded first
        ,'MathHelper.cs'
        ,'StringUtilities.vb'
        
        # PowerShell classes should be loaded after compiled classes
        ,'ConfigurationManager.ps1'
        
        # ,'class1.ps1'
        # ,'class2.cs'
        # ,'class3.js'
        # ,'class4.vb'
    )
}