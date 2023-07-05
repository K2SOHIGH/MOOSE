#!/usr/bin/env python3
import os
import yaml
from . import log
import logging
import hashlib


logger = log.setlogger(__name__)

class Samples:
    def __init__(self,yamlfile=None):
        self.samples = self.init_samples_from_yaml(yamlfile)

    def init_samples_from_yaml(self,yamlfile):
        _ = {}
        if yamlfile is not None and os.path.exists(yamlfile):
            samples = yaml.load(open(yamlfile) , Loader = yaml.SafeLoader)            
            for sid, sample in samples.items():
                _[sid] = Sample(sid,sample)        
        return _

    def get_sample_by_id(self,sid):        
        return self.samples[sid]
        
    def merge_sample(self,sample_id , samples):
        merged_sample = Sample(sample_id)                    
        for sid in samples:
            sample = self.get_sample_by_id(sid)
            merged_sample.forward += sample.forward
            merged_sample.reverse += sample.reverse
            merged_sample.single += sample.single
            merged_sample.long += sample.long
            if not merged_sample.long_reads_type:
                merged_sample.long_reads_type = sample.long_reads_type
            elif merged_sample.long_reads_type != sample.long_reads_type:
                logger.error("Long reads are not of the same type, samples [{}] canno't be merged".format(sample_id))                        
                exit(-1)
        return merged_sample       

    def _read_entry(self, reads , reads_type):
        rd = {}
        if reads:
            for r in reads:
                hs = hashlib.sha256(
                    os.path.abspath(r).encode('utf-8')
                ).hexdigest()
                if hs not in rd:
                    rd[reads_type + "_" + hs] = r    
        return rd

    def _pe_read_entry(self, forward , reverse):
        rd = {}
        if forward and reverse:
            for f,r in zip(forward,reverse):
                hs = hashlib.sha256(
                    os.path.abspath(f).encode('utf-8')
                ).hexdigest()
                if hs not in rd:
                    rd["forward_" + hs] = f
                    rd["reverse_" + hs] = r
        return rd

    def sample2reads(self):
        reads = {}
        for sid, sample in self.samples.items():
            reads.update( self._pe_read_entry(sample.forward , sample.reverse) )        
            reads.update( self._read_entry(sample.single , "single")  )
            reads.update( self._read_entry(sample.long , "long")    )
        return reads             


class Sample:
    def __init__(self, sid , sample = {"reads":{}} ):
        self._sid = sid
        self._forward = [ pe.split(";")[0]  for pe in sample["reads"]["paired_end"]] \
            if "paired_end" in sample["reads"] else []
        self._reverse = [ pe.split(";")[1]  for pe in sample["reads"]["paired_end"]] \
             if "paired_end" in sample["reads"] else []
        self._single  = sample["reads"]["single_reads"] if "single_reads" in sample["reads"] else []
        self._long    = sample["reads"]["long_reads"] if "long_reads" in sample["reads"] else []
        self._long_reads_type = sample["long_reads_type"] if "long_reads_type" in sample  else []
        self._sample_validation()

    def __str__(self):
        return "{sid}\n\tforward_reads : \n\t\t - {frw} \n\treverse_reads : \n\t\t - {rev} \n\tsingle_end_reads : \n\t\t - {se} \n\tlong_reads : \n\t\t - {lr}".format(
            sid = self._sid,
            frw = "\n\t\t - ".join(self._forward),
            rev = "\n\t\t - ".join(self._reverse),
            se = "\n\t\t - ".join(self._single),
            lr = "\n\t\t - ".join(self._long),
        )

    def _sample_validation(self):
        if len(self._forward) != len(self._reverse):
            logger.error("same number of forward and reverse reads should be provided [{}]. bye".format(self._sid) )
            exit(-1)


    @property
    def long_reads_type(self):                
        return self._long_reads_type

    @long_reads_type.setter
    def long_reads_type(self, value):
        self._long_reads_type = str(value)

    @long_reads_type.deleter
    def long_reads_type(self):
        del self._long_reads_type

    @property
    def sid(self):                
        return self._sid

    @sid.setter
    def sid(self, value):
        self._sid = str(value)

    @sid.deleter
    def sid(self):
        del self._sid        

    @property
    def forward(self):                
        return self._forward

    @forward.setter
    def forward(self, value):
        if isinstance(value,list):
            self._forward = value
        else:
            logger.error("Reads should be provided as list.")
            exit(-1)

    @forward.deleter
    def forward(self):
        del self._forward

    @property
    def reverse(self):                
        return self._reverse

    @reverse.setter
    def reverse(self, value):
        if isinstance(value,list):
            self._reverse = value
        else:
            logger.error("Reads should be provided as list.")
            exit(-1)

    @reverse.deleter
    def reverse(self):
        del self._reverse

    @property
    def single(self):                
        return self._single

    @single.setter
    def single(self, value):
        if isinstance(value,list):
            self._single = value
        else:
            logger.error("Reads should be provided as list.")
            exit(-1)

    @single.deleter
    def single(self):
        del self._single

    @property
    def long(self):                
        return self._long

    @long.setter
    def long(self, value):
        if isinstance(value,list):
            self._long = value
        else:
            logger.error("Reads should be provided as list.")
            exit(-1)

    @long.deleter
    def long(self):
        del self._long                        

    
    