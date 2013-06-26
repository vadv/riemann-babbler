#include "sysinfo.h"
#include <ruby.h>
#include <sys/sysinfo.h>
#include <sys/statvfs.h>

/*  Begin FS Part  */
static void	get_fs_size_stat(const char *fs, uint64_t *total, uint64_t *free,
		uint64_t *used, double *pfree, double *pused)
{
	struct statvfs	s;

	if (0 != statvfs(fs, &s))
		rb_raise(rb_eRuntimeError, "statvfs call");

	if (total)
		*total = (uint64_t)s.f_blocks * s.f_frsize;
	if (free)
		*free = (uint64_t)s.f_bavail * s.f_frsize;
	if (used)
		*used = (uint64_t)(s.f_blocks - s.f_bfree) * s.f_frsize;
	if (pfree)
	{
		if (0 != s.f_blocks - s.f_bfree + s.f_bavail)
			*pfree = (double)(100.0 * s.f_bavail) /
					(s.f_blocks - s.f_bfree + s.f_bavail);
		else
			*pfree = 0;
	}
	if (pused)
	{
		if (0 != s.f_blocks - s.f_bfree + s.f_bavail)
			*pused = 100.0 - (double)(100.0 * s.f_bavail) /
					(s.f_blocks - s.f_bfree + s.f_bavail);
		else
			*pused = 0;
	}
}

static int	VFS_FS_USED(VALUE self, VALUE mount)
{
	uint64_t	value = 0;
	get_fs_size_stat(RSTRING_PTR(mount), NULL, NULL, &value, NULL, NULL);
	return INT2NUM(value);
}

static int	VFS_FS_TOTAL(VALUE self, VALUE mount)
{
	uint64_t	value = 0;
	get_fs_size_stat(RSTRING_PTR(mount), &value, NULL, NULL, NULL, NULL);
	return INT2NUM(value);
}

static int	VFS_FS_FREE(VALUE self, VALUE mount)
{
	uint64_t	value = 0;
	get_fs_size_stat(RSTRING_PTR(mount), NULL, &value, NULL, NULL, NULL);
	return INT2NUM(value);
}

static int	VFS_FS_PFREE(VALUE self, VALUE mount)
{
	double	value = 0;
	get_fs_size_stat(RSTRING_PTR(mount), NULL, NULL, NULL, &value, NULL);
	return rb_float_new(value);
}

static int	VFS_FS_PUSED(VALUE self, VALUE mount)
{
	double	value = 0;
	get_fs_size_stat(RSTRING_PTR(mount), NULL, NULL, NULL, NULL, &value);
	return INT2NUM(value);
}

/* ---------- INODE ---------- */
union _val {
  unsigned long long ul_val;
  double d_val;
};

static void get_fs_inodes_stat(const char *fs, int type,union  _val * val)
{
  struct statvfs   s;
  if ( statvfs( fs, &s) != 0 )
  {
    rb_raise(rb_eRuntimeError, "statvfs call");
  }
  switch(type)
  {
    case 1: val->ul_val = (unsigned long long )(s.f_files); break;
    case 2: val->ul_val  = (unsigned long long )(s.f_favail); break;
    case 3: val->ul_val = (unsigned long long )(s.f_files - s.f_favail); break;
    case 4:
        	if (0 != s.f_files){
            	val->d_val = (100.0 * (s.f_files - s.f_favail)) / s.f_files;
        	} else
            	*(double *)val = 0; 
            break;
  }
}

static int	VFS_FS_INODE_PUSED(VALUE self, VALUE mount)
{
	union _val val;
	get_fs_inodes_stat(RSTRING_PTR(mount), 4, &val );
	return rb_float_new(val.d_val);
}

static int	VFS_FS_INODE_USED(VALUE self, VALUE mount)
{
	union _val val;
	get_fs_inodes_stat(RSTRING_PTR(mount), 3, &val );
	return INT2NUM(val.ul_val);
}

static int	VFS_FS_INODE_FREE(VALUE self, VALUE mount)
{
	union _val val;
	get_fs_inodes_stat(RSTRING_PTR(mount), 2, &val );
	return INT2NUM(val.ul_val);
}

static int	VFS_FS_INODE_TOTAL(VALUE self, VALUE mount)
{
	union _val val;
	get_fs_inodes_stat(RSTRING_PTR(mount), 1, &val );
	return INT2NUM(val.ul_val);
}

/*  End FS Part  */

/* Begin Memory Part */
static int	VM_MEMORY_CACHED(VALUE self)
{
	FILE	*f;
	char	*t;
	char	c[MAX_STRING_LEN];
	uint64_t	res = 0;

	if(NULL == (f = fopen("/proc/meminfo","r") ))
	{
		rb_raise(rb_eRuntimeError, "fail to read /proc/meminfo");
	}
	while(NULL!=fgets(c,MAX_STRING_LEN,f))
	{
		if(strncmp(c,"Cached:",7) == 0)
		{
			t=(char *)strtok(c," ");
			t=(char *)strtok(NULL," ");
			sscanf(t, FS_UI64, &res );
			t=(char *)strtok(NULL," ");

			if(strcasecmp(t,"kb"))		res <<= 10;
			else if(strcasecmp(t, "mb"))	res <<= 20;
			else if(strcasecmp(t, "gb"))	res <<= 30;
			else if(strcasecmp(t, "tb"))	res <<= 40;

			break;
		}
	}
	fclose(f);
	return INT2NUM(res);
}

static int	VM_MEMORY_BUFFERS(VALUE self)
{
	struct sysinfo info;
	if( 0 == sysinfo(&info))
	{
		return INT2NUM(info.bufferram);
	}
	else
		rb_raise(rb_eRuntimeError, "sysinfo call");
}

static int	VM_MEMORY_SHARED(VALUE self)
{
	struct sysinfo info;
	if( 0 == sysinfo(&info))
	{
		return INT2NUM(info.sharedram);
	}
	else
		rb_raise(rb_eRuntimeError, "sysinfo call");
}

static int	VM_MEMORY_TOTAL(VALUE self)
{
	struct sysinfo info;
	if( 0 == sysinfo(&info))
	{
		return INT2NUM(info.totalram);
	}
	else
		rb_raise(rb_eRuntimeError, "sysinfo call");
}

static int	VM_MEMORY_FREE(VALUE self)
{
	struct sysinfo info;
	if( 0 == sysinfo(&info))
	{
		return INT2NUM(info.freeram);
	}
	else
		rb_raise(rb_eRuntimeError, "sysinfo call");
}
static int      VM_MEMORY_AVAILABLE(VALUE self)
{
	struct sysinfo info;
	if( 0 == sysinfo(&info))
	{
		return INT2NUM(info.freeram + info.bufferram + VM_MEMORY_CACHED(self));
	}
	else
		rb_raise(rb_eRuntimeError, "sysinfo call");
}
/* End Memory Part */

/* Begin Net Part */
typedef struct
{
	uint64_t ibytes;
	uint64_t ipackets;
	uint64_t ierr;
	uint64_t idrop;
	uint64_t obytes;
	uint64_t opackets;
	uint64_t oerr;
	uint64_t odrop;
	uint64_t colls;
}
net_stat_t;


static void	get_net_stat(const char *if_name, net_stat_t *result)
{
	char line[MAX_STRING_LEN];
	char name[MAX_STRING_LEN];

	uint64_t tmp = 0;

	FILE *f;
	char	*p;

	if(NULL != (f = fopen("/proc/net/dev","r") ))
	{
		while(fgets(line,MAX_STRING_LEN,f) != NULL)
		{
			p = strstr(line,":");
			if(p) p[0]='\t';

			if(sscanf(line,"%s\t" FS_UI64 "\t" FS_UI64 "\t" FS_UI64 "\t" FS_UI64 "\t" FS_UI64 "\t"
					FS_UI64 "\t" FS_UI64 "\t" FS_UI64 "\t \
					" FS_UI64 "\t" FS_UI64 "\t" FS_UI64 "\t" FS_UI64 "\t" FS_UI64 "\t"
					FS_UI64 "\t" FS_UI64 "\t" FS_UI64 "\n",
				name,
				&(result->ibytes),	/* bytes */
				&(result->ipackets),	/* packets */
				&(result->ierr),	/* errs */
				&(result->idrop),	/* drop */
				&(tmp),			/* fifo */
				&(tmp),			/* frame */
				&(tmp),			/* compressed */
				&(tmp),			/* multicast */
				&(result->obytes),	/* bytes */
				&(result->opackets),	/* packets*/
				&(result->oerr),	/* errs */
				&(result->odrop),	/* drop */
				&(tmp),			/* fifo */
				&(result->colls),	/* icolls */
				&(tmp),			/* carrier */
				&(tmp)			/* compressed */
				) == 17)
			{
				if(strncmp(name, if_name, MAX_STRING_LEN) == 0)
				{
					break;
				}
			}
		}
		fclose(f);
	}
}

int	NET_IF_IN(VALUE self, VALUE my_if_name, VALUE my_mode)
{
	net_stat_t	ns;

	char *if_name = RSTRING_PTR(my_if_name);
	char *mode = RSTRING_PTR(my_mode);

	get_net_stat(if_name, &ns);
	if(strncmp(mode, "bytes", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.ibytes);
	}
	else if(strncmp(mode, "packets", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.ipackets);
	}
	else if(strncmp(mode, "errors", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.ierr);
	}
	else if(strncmp(mode, "dropped", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.idrop);
	}
	else
		rb_raise(rb_eRuntimeError, "give me mode");
}

int	NET_IF_OUT(VALUE self, VALUE my_if_name, VALUE my_mode)
{
	net_stat_t	ns;

	char *if_name = RSTRING_PTR(my_if_name);
	char *mode = RSTRING_PTR(my_mode);

	get_net_stat(if_name, &ns);

	if (strncmp(mode, "bytes", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.obytes);
	}
	else if(strncmp(mode, "packets", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.opackets);
	}
	else if(strncmp(mode, "errors", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.oerr);
	}
	else if(strncmp(mode, "dropped", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.odrop);
	}
	else
		rb_raise(rb_eRuntimeError, "give me mode");
}

int	NET_IF_TOTAL(VALUE self, VALUE my_if_name, VALUE my_mode)
{
	net_stat_t	ns;

	char *if_name = RSTRING_PTR(my_if_name);
	char *mode = RSTRING_PTR(my_mode);

	get_net_stat(if_name, &ns);
	if(strncmp(mode, "bytes", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.obytes + ns.ibytes);
	}
	else if(strncmp(mode, "packets", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.opackets + ns.ipackets);
	}
	else if(strncmp(mode, "errors", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.oerr + ns.ierr);
	}
	else if(strncmp(mode, "dropped", MAX_STRING_LEN) == 0)
	{
		return INT2NUM(ns.odrop + ns.idrop);
	}
	else
		rb_raise(rb_eRuntimeError, "give me mode");
}

int	NET_IF_COLLISIONS(VALUE self, VALUE my_if_name)
{
	net_stat_t	ns;
	char *if_name = RSTRING_PTR(my_if_name);

	get_net_stat(if_name, &ns);
	return INT2NUM(ns.odrop);
}

/* End Net Part */

/* Begin Cpu Part */
int SYSTEM_CPU_SWITCHES(VALUE self)
{
	char		line[MAX_STRING_LEN], name[32];
	uint64_t	value = 0;
	FILE		*f;

	if (NULL == (f = fopen("/proc/stat", "r")))
		rb_raise(rb_eRuntimeError, "Can't open /proc/stat");

	while (NULL != fgets(line, sizeof(line), f))
	{
		if (2 != sscanf(line, "%s " FS_UI64, name, &value))
			continue;

		if (0 == strcmp(name, "ctxt"))
		{
			return INT2NUM(value);
			break;
		}
	}
	fclose(f);
}
/* End Cpu Part */

void Init_sysinfo(void) {
 
  VALUE mSI = rb_define_module("SysInfo");
  VALUE mFS = rb_define_module_under(mSI, "FS");
  VALUE cBlock = rb_define_class_under(mFS, "Block", rb_cObject);
  VALUE cInode = rb_define_class_under(mFS, "Inode", rb_cObject);
  VALUE cMem = rb_define_class_under(mSI, "Memory", rb_cObject);
  VALUE cNet = rb_define_class_under(mSI, "Net", rb_cObject);
  VALUE cCpu = rb_define_class_under(mSI, "Cpu", rb_cObject);

  rb_define_singleton_method(cBlock,
    "used", VFS_FS_USED, 1);

  rb_define_singleton_method(cBlock,
    "free", VFS_FS_FREE, 1);

  rb_define_singleton_method(cBlock,
    "total", VFS_FS_TOTAL, 1);

  rb_define_singleton_method(cBlock,
    "pfree", VFS_FS_PFREE, 1);

  rb_define_singleton_method(cBlock,
    "pused", VFS_FS_PUSED, 1);

  rb_define_singleton_method(cInode,
    "used", VFS_FS_INODE_USED, 1);

  rb_define_singleton_method(cInode,
    "free", VFS_FS_INODE_FREE, 1);

  rb_define_singleton_method(cInode,
    "total", VFS_FS_INODE_TOTAL, 1);

  rb_define_singleton_method(cInode,
    "pused", VFS_FS_INODE_PUSED, 1);

  rb_define_singleton_method(cMem,
    "cached", VM_MEMORY_CACHED, 0);

  rb_define_singleton_method(cMem,
    "buffers", VM_MEMORY_BUFFERS, 0);

  rb_define_singleton_method(cMem,
    "shared", VM_MEMORY_SHARED, 0);

  rb_define_singleton_method(cMem,
    "total", VM_MEMORY_TOTAL, 0);

  rb_define_singleton_method(cMem,
    "free", VM_MEMORY_FREE, 0);

  rb_define_singleton_method(cMem,
    "avaiable", VM_MEMORY_AVAILABLE, 0);

  rb_define_singleton_method(cNet,
    "in", NET_IF_IN, 2);

  rb_define_singleton_method(cNet,
    "out", NET_IF_OUT, 2);

  rb_define_singleton_method(cNet,
    "total", NET_IF_TOTAL, 2);

  rb_define_singleton_method(cNet,
    "collisions", NET_IF_COLLISIONS, 1);

  rb_define_singleton_method(cCpu,
    "switches", SYSTEM_CPU_SWITCHES, 0);  

}