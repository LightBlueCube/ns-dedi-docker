# Northstar Dedicated Server Docker Image

[让我们说中文](#配置)

### Setup

| Container path 	| Purpose 					| Description 			|
| --- 				| --- 						| --- 					|
| `/mnt/northstar` 	| NorthstarLuncher files 	| Required, read-only 	|
| `/mnt/mods` 		| Mods directory 			| Optional, read-only 	|
| `/mnt/plugins` 	| Plugin directory 			| Optional, read-only 	|


| ENVs 						| Description 																								|
| --- 						| --- 																										|
| `SRVPATH` 				| Server root directory<br/>This normally should not be changed 											|
| `ENTRY` 					| The entry executable file<br/>This normally should not be changed 										|
| `MODPATH` 				| The `entrypoint.sh` synchronizes `/mnt/mods` to here<br/>This normally should not be changed				|
| `PLUGINPATH` 				| The `entrypoint.sh` replaces it with a symlink to `/mnt/plugins`<br/>This normally should not be changed 	|
| `NS_WINE_PREFIX` 			| WINEPREFIX<br/>This normally should not be changed 														|
| `REQUIRED_STARTUP_ARGS` 	| Some required arguments for the dedicated server<br/>This normally should not be changed 					|
| `NS_STARTUP_ARGS` 		| Server startup arguments. Use it in the same way as `ns_startup_args_dedi.txt` 							|
| `PORT_TCP` 				| See `autoexec_ns_server.cfg` > `ns_player_auth_port` 														|
| `PORT_UDP` 				| Passed through via `-port $PORT_UDP` 																		|
| `SRV_NAME` 				| See `autoexec_ns_server.cfg` > `ns_server_name` 															|
| `SRV_DESC` 				| See `autoexec_ns_server.cfg` > `ns_server_desc` 															|


#### Overrides autoexec_ns_server.cfg

To override a setting, define an ENV with the same name as the setting in `autoexec_ns_server.cfg`

For example:

```bash
-e ns_auth_allow_insecure=1
-e ns_should_return_to_lobby=0
```

----

An example command for starting a server:
```bash
docker run --rm \
	-v /home/r2ds/r2ns_v1_18:/mnt/northstar:ro \
	-v /home/r2ds/my_mods:/mnt/mods:ro \
	-e ns_auth_allow_insecure=1 \
	-e ns_should_return_to_lobby=0 \
	-e NS_STARTUP_ARGS=' +mp_gamemode ps +map mp_glitch +setplaylist ps +setplaylistvaroverrides "max_players 10"' \
	-e PORT_TCP=11451 -e PORT_UDP=41919 \
	-p 11451:11451/tcp \
	-p 41919:41919/udp \
	ghcr.io/lightbluecube/ns-dedi-docker/northstar-dedi
```

### Build

Make sure you have placed the slimmed-down base Titanfall 2 files in `R2N/`

If you does not have one, check the Releases of this repository

```bash
docker buildx build -t nsdedi -f dockerfile .
```

<br/>

### 配置

| 容器路径 			| 用途 						| 描述 				|
| --- 				| --- 						| --- 				|
| `/mnt/northstar` 	| NorthstarLauncher 文件 	| 必需，只读 			|
| `/mnt/mods` 		| 模组目录 					| 可选，只读 			|
| `/mnt/plugins` 	| 插件目录 					| 可选，只读 			|


| 环境变量 					| 描述 																			|
| --- 						| --- 																			|
| `SRVPATH` 				| 服务器根目录<br/>无特殊需求不应修改 												|
| `ENTRY` 					| 入口可执行文件<br/>无特殊需求不应修改 												|
| `MODPATH` 				| `entrypoint.sh` 会将 `/mnt/mods` 同步到此路径<br/>无特殊需求不应修改				|
| `PLUGINPATH` 				| `entrypoint.sh` 会将其替换为指向 `/mnt/plugins` 的符号链接<br/>无特殊需求不应修改 	|
| `NS_WINE_PREFIX` 			| WINEPREFIX<br/>无特殊需求不应修改 												|
| `REQUIRED_STARTUP_ARGS` 	| 专用服务器必需的一些启动参数<br/>无特殊需求不应修改 									|
| `NS_STARTUP_ARGS` 		| 服务器启动参数。使用方式参照 `ns_startup_args_dedi.txt` 							|
| `PORT_TCP` 				| 参见 `autoexec_ns_server.cfg` > `ns_player_auth_port` 							|
| `PORT_UDP` 				| 通过 `-port $PORT_UDP` 传递 													|
| `SRV_NAME` 				| 参见 `autoexec_ns_server.cfg` > `ns_server_name` 								|
| `SRV_DESC` 				| 参见 `autoexec_ns_server.cfg` > `ns_server_desc` 								|


#### 覆盖 autoexec_ns_server.cfg 配置

要覆盖某个配置项，定义一个与 `autoexec_ns_server.cfg` 中配置项同名的环境变量

示例：

```bash
-e ns_auth_allow_insecure=1
-e ns_should_return_to_lobby=0
```

----

一个启动服务器的示例命令：
```bash
docker run --rm \
	-v /home/r2ds/r2ns_v1_18:/mnt/northstar:ro \
	-v /home/r2ds/my_mods:/mnt/mods:ro \
	-e ns_auth_allow_insecure=1 \
	-e ns_should_return_to_lobby=0 \
	-e NS_STARTUP_ARGS=' +mp_gamemode ps +map mp_glitch +setplaylist ps +setplaylistvaroverrides "max_players 10"' \
	-e PORT_TCP=11451 -e PORT_UDP=41919 \
	-p 11451:11451/tcp \
	-p 41919:41919/udp \
	ghcr.io/lightbluecube/ns-dedi-docker/northstar-dedi
```

### 构建

确保已将精简后的ttf2基础文件放在 `R2N/` 目录中

如果你并没有一个，查看这个仓库的Releases

```bash
docker buildx build -t nsdedi -f dockerfile .
```
