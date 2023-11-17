import runpy

#
# See also `examples.sh`
#

runpy.run_module('file_encoder', run_name='__main__')
runpy.run_module('file_decoder', run_name='__main__')
runpy.run_module('node_recovery_source', run_name='__main__')
runpy.run_module('node_recovery_client', run_name='__main__')
