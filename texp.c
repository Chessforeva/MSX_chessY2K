/*

 texp.exe - compacts TASM  .EXP export file ready for assembler to include

 Compiled on LCC-WIN32

*/

#include <stdio.h>
#include <string.h>

int readDatas( FILE *fi, char *buf, int maxLen )
{
	char *p = buf;
	int l = 0;
	for(;!feof(fi); )
		{
		fread(p,1,1,fi); l++;
		if( (*p)==13 || (*p)==10 || (l+2)>maxLen )
		   	{
			 *(++p) = 0;
			 break;
			}
		p++;
		}
	return l;
}


// MAIN PROGRAM
int main(int argc,char *argv[])
{
	if(argc<2)
		{
		printf("Prepares TASM .EXP file for including\n into next assembler source ");
		printf(" by  #include  command,\n mostly removes syntax conflicting details.\n\n");
		printf("  usage: texp <.EXP-file>\n\n");
		printf("Press a key, exiting.\n\n");
		getchar();
		return(0);
		}
	char equ[] = ".EQU\0";
	char was=0;
	char *fname = argv[1], *ext;
	char fnm[1024], bf[2048];

	strcpy(fnm, fname);
	ext = fnm+strlen(fnm)-3;
	strcpy(ext,"tmp");

	FILE *I = fopen (fname, "r");

	// TASM generates lowercase extension too
	if(I==NULL)
	 {
	  strcpy(ext,"exp");
	  I = fopen (fnm, "r");
	 }
	FILE *O = fopen (fnm, "w");
	while( readDatas(I,bf,2047)>0 )
		{
		char *c = strchr(bf,';');
		if(c!=NULL)	*(c)=0;
		if(!(strstr(bf,equ)==NULL || bf[0]==' '))
			{
			c = strchr(bf,' ');
			while(*(++c)==' ');
			if(strncmp(c,equ,4)==0)
				{
				fprintf(O,"%s\n",bf); was=1;
				}
			}
		}
	fclose(I);
	fclose(O);
	if(!was)
	    {
		remove(fnm);
		remove(fname);
	    printf("No exported labels\nRemoving export file.\n" );
	    }
	else
	   	{
		remove(fname);
		rename(fnm,fname);
		printf("Done.\n" );
		}
	return(0);
}


