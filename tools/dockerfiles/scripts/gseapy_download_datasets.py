import os
import json
import requests

from gseapy.utils import DEFAULT_CACHE_PATH, retry, mkdirs


def get_libraries():
    lib_url='http://amp.pharm.mssm.edu/Enrichr/datasetStatistics'
    response = requests.get(lib_url)
    if not response.ok:
        raise Exception("Error getting the Enrichr libraries")
    libs_json = json.loads(response.text)
    libs = [lib['libraryName'] for lib in libs_json['statistics']]
    return sorted(libs)


def parse_lib(libname):
    tmpname = "enrichr." + libname + ".gmt"
    tempath = os.path.join(DEFAULT_CACHE_PATH, tmpname)
    if os.path.isfile(tempath):
        print("Already downloaded", libname)
    else:
        return download_library(libname)


def download_library(libname):
    print("Downloading: ", libname)
    s = retry(5)
    ENRICHR_URL = 'http://amp.pharm.mssm.edu/Enrichr/geneSetLibrary'
    query_string = '?mode=text&libraryName=%s'
    response = s.get( ENRICHR_URL + query_string % libname, timeout=None)
    if not response.ok:
        raise Exception('Error fetching enrichment results, check internet connection first.')
    mkdirs(DEFAULT_CACHE_PATH)
    genesets_dict = {}
    outname = "enrichr.%s.gmt"%libname
    gmtout = open(os.path.join(DEFAULT_CACHE_PATH, outname), "w")
    for line in response.iter_lines(chunk_size=1024, decode_unicode='utf-8'):
        line=line.strip()
        k = line.split("\t")[0]
        v = list(map(lambda x: x.split(",")[0], line.split("\t")[2:]))
        genesets_dict.update({ k: v})
        outline = "%s\t\t%s\n"%(k, "\t".join(v))
        gmtout.write(outline)
    gmtout.close()
    return genesets_dict


for libname in get_libraries():
    try:
        parse_lib(libname)
    except Exception as err:
        pass
