local k = import 'k.libsonnet';

{
  new(name='tuwunel', namespace='matrix', config={}):: {
    local cfg = {
      image: 'ghcr.io/matrix-construct/tuwunel:latest',
      serverName: 'localhost',
      port: 8008,
      dataPath: '/var/lib/tuwunel',
      storageSize: '2Gi',
      allowRegistration: true,
      allowFederation: false,
      allowEncryption: false,
      logLevel: 'info',
      resources: {
        requests: { memory: '256Mi', cpu: '100m' },
        limits: { memory: '512Mi', cpu: '500m' },
      },
    } + config,

    namespace: k.core.v1.namespace.new(namespace),

    configmap: k.core.v1.configMap.new(name + '-config', {
      TUWUNEL_SERVER_NAME: cfg.serverName,
      TUWUNEL_DATABASE_PATH: cfg.dataPath,
      TUWUNEL_PORT: std.toString(cfg.port),
      TUWUNEL_ADDRESS: '["0.0.0.0"]',
      TUWUNEL_ALLOW_REGISTRATION: std.toString(cfg.allowRegistration),
      TUWUNEL_ALLOW_FEDERATION: std.toString(cfg.allowFederation),
      TUWUNEL_ALLOW_ENCRYPTION: std.toString(cfg.allowEncryption),
      TUWUNEL_LOG: cfg.logLevel,
    }) + k.core.v1.configMap.metadata.withNamespace(namespace),

    pvc: k.core.v1.persistentVolumeClaim.new(name + '-data')
      + k.core.v1.persistentVolumeClaim.metadata.withNamespace(namespace)
      + k.core.v1.persistentVolumeClaim.spec.withAccessModes(['ReadWriteOnce'])
      + k.core.v1.persistentVolumeClaim.spec.resources.withRequests({
        storage: cfg.storageSize,
      }),

    local container = k.core.v1.container.new(name, cfg.image)
      + k.core.v1.container.withPorts([
        k.core.v1.containerPort.newNamed(cfg.port, 'http'),
      ])
      + k.core.v1.container.withEnvFrom([
        { configMapRef: { name: name + '-config' } },
        { secretRef: { name: name + '-secrets' } },
      ])
      + k.core.v1.container.withVolumeMounts([
        k.core.v1.volumeMount.new(name + '-data', cfg.dataPath),
      ])
      + k.core.v1.container.resources.withRequests(cfg.resources.requests)
      + k.core.v1.container.resources.withLimits(cfg.resources.limits)
      + k.core.v1.container.livenessProbe.httpGet.withPath('/_matrix/client/versions')
      + k.core.v1.container.livenessProbe.httpGet.withPort(cfg.port)
      + k.core.v1.container.livenessProbe.withInitialDelaySeconds(30)
      + k.core.v1.container.livenessProbe.withPeriodSeconds(30)
      + k.core.v1.container.readinessProbe.httpGet.withPath('/_matrix/client/versions')
      + k.core.v1.container.readinessProbe.httpGet.withPort(cfg.port)
      + k.core.v1.container.readinessProbe.withInitialDelaySeconds(5)
      + k.core.v1.container.readinessProbe.withPeriodSeconds(10),

    deployment: k.apps.v1.deployment.new(name, replicas=1, containers=[container])
      + k.apps.v1.deployment.metadata.withNamespace(namespace)
      + k.apps.v1.deployment.spec.template.spec.withVolumes([
        k.core.v1.volume.fromPersistentVolumeClaim(name + '-data', name + '-data'),
      ]),

    service: k.core.v1.service.new(name, { name: name }, [
      k.core.v1.servicePort.new(cfg.port, cfg.port) + k.core.v1.servicePort.withName('http'),
    ]) + k.core.v1.service.metadata.withNamespace(namespace),
  },
}
