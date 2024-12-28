call rsvars.bat
%systemroot%\microsoft.net\framework\v4.0.30319\msbuild /t:Clean LNode.dproj
%systemroot%\microsoft.net\framework\v4.0.30319\msbuild /t:Build /p:Config=Release;Platform=Linux64 LNode.dproj