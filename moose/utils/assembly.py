import logging
try:
    from . import log
    logger = log.setlogger(__name__)     
except ModuleNotFoundError:
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)


class AssemblyWorkflow:
    workflows = {
        "SRF": ["spades","unicycler"],
        "SRO": ["megahit","spades","unicycler"],
        "LRF": ["miniasm"],
    }

    def __init__(self,w):
        self._workflow = w
        self._assemblers = None
        if w in AssemblyWorkflow.workflows : 
            AssemblyWorkflow.workflows[w]
        else:
            logger.error("%s is not a valid workflows" % w)
            exit(-1)

    @property
    def workflow(self):
        return self._workflow

    @property
    def assemblers(self):
        return self._assemblers

    @assemblers.setter
    def assemblers(self, list_of_assemblers):
        v = self._validate(list_of_assemblers)
        if v:
            self._assemblers = v
        else:
            logger.error("No valid assembler defined for %s" % self.workflow)
            exit(-1)


    def _validate(self , assemblers):
        l = []
        for a in assemblers:        
            if a not in AssemblyWorkflow.workflows[self.workflow]:
                logger.warning("%s is not supported for %s workflow and will not be used" % (a,self.workflow))
            else:
                l.append(a)                
        return l



def setup_workflows(workflows, assemblers):         
    WORKFLOWS = {}    
    for w in workflows:  
        w = AssemblyWorkflow(w)
        w.assemblers = assemblers
        WORKFLOWS[w.workflow] = w.assemblers
    return WORKFLOWS


def validate_samples(SAMPLES,WORKFLOWS):    
    for sid, SAMPLE in SAMPLES.samples.items():          
        if (len(SAMPLE.forward)==0 and len(SAMPLE.single)==0) and ("SRO" in WORKFLOWS or "SRF" in WORKFLOWS) :
            logger.warning("Can't perform SRO, SRF neither LRF assembly if you\
                    don't provide short reads [sample accession : {}]".format(sid))
            return False
        if (len(SAMPLE.long)==0 )  and ("SRF" in WORKFLOWS or "LRF" in WORKFLOWS) :
            logger.warning("Can't perform SRF / LRF assembly if you\
                    don't provide long reads [sample accession : {}]".format(sid))
            return False
    
    return True
