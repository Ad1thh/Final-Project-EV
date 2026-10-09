import vitis
import inspect

client = vitis.create_client()
print("SIGNATURE:", inspect.signature(client.create_platform_component))
print("DOC:", client.create_platform_component.__doc__)
print("CREATE_APP_SIGNATURE:", inspect.signature(client.create_app_component))
print("CREATE_APP_DOC:", client.create_app_component.__doc__)
