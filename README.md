**Windows Help (.hlp files) Support Installer**

I had the need to restore the support for the old Windows Help 32-bit files,
which Microsoft has removed from any version of Windows since Windows Vista /
Windows Server 2008.

If you are using any version of Windows which is not Windows 10 or Windows
Server 2016/2019 you are in luck, as Microsoft does still provide an OS update
to restore the support for that old file format. If it isn't the case, the only
solution is to resort to an hack by injecting the needed files, using the
closest supported OS update (Windows 8.1 / Windows Server 2012 as of this
writing) as the source.

TBH, on the net there are other scripts that more or less fullfil the same goal.
Mine has the following features:

-   It supports any version of Windows starting from Windows Vista, and
    including Windows Server

-   It supports any language you've chosen for your system, among the ones
    provided by Microsoft

-   It doesn't include any proprietary file (i.e. the various Windows KB needed,
    or any file extracted from them) making the script freely distributable. The
    Windows KB are downloaded from the Microsoft web sites. The drawback is that
    you will need to provide the GNU *wget* binary and place it in the same
    directory where this script lies.

-   It restores the original set of ACL on the hacked files.

As for *wget*, many web sites offer a compiled (binary) version for Windows. The
one I have used is currently available at
<https://eternallybored.org/misc/wget/releases/wget-1.20.3-win32.zip>, but any
other distro should be as much as useful within the scope of this script.
