local tuwunel = import 'tuwunel.libsonnet';

tuwunel.new(
  name='tuwunel',
  namespace='matrix',
  config={
    serverName: 'localhost',
  },
)
