/*
 * comptest: reads the battery of the Apple Watch paired with an iPhone, through the
 * iPhone's companion_proxy service.
 *
 * Origin: https://gist.github.com/nikias/ebc6e975dc908f3741af0f789c5b1088
 * (Nikias Bassen, libimobiledevice), revision f98832d8 (2020-07-31), file
 * sha256:58233dbbb276fae5be48b3891ef795c1f06b880faf17caa4cdfd596e49c9347b.
 *
 * Changes for AirBattery (matching the binary shipped by lihaoyun6 in 2024):
 * - print the full watch UDID ("Checking watch <udid>"): AirBattery uses it as the
 *   device ID;
 * - also query "DeviceName", which AirBattery shows as the watch's name;
 * - initialize `device` and check the lookup result: idevice_new_with_options() leaves
 *   `device` untouched when the phone is not reachable, so the uninitialized pointer
 *   was used and freed later, crashing comptest (upstream AirBattery #198);
 * - check that companion_proxy started, and unsubscribe from device events on exit.
 */
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <inttypes.h>
#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/companion_proxy.h>
#include <plist/plist.h>

static int quit_flag = 0;

static void get_value_from_watch(idevice_t device, const char* udid, const char* key)
{
	companion_proxy_client_t cpx = NULL;
	companion_proxy_error_t cerr = companion_proxy_client_start_service(device, &cpx, NULL);
	if (cerr != COMPANION_PROXY_E_SUCCESS) {
		printf("Failed to start companion_proxy (%d)!\n", cerr);
		return;
	}
	plist_t val = NULL;
	cerr = companion_proxy_get_value_from_registry(cpx, udid, key, &val);
	companion_proxy_client_free(cpx);

	if (cerr == COMPANION_PROXY_E_SUCCESS) {
		plist_t node = plist_dict_get_item(val, key);
		switch (plist_get_node_type(node)) {
		case PLIST_UINT: {
			uint64_t u64val = 0;
			plist_get_uint_val(node, &u64val);
			printf("%s: %" PRIu64 "\n", key, u64val);
			break;
		}
		case PLIST_STRING: {
			char* strval = NULL;
			plist_get_string_val(node, &strval);
			if (!strcmp(key, "SerialNumber")) {
				printf("%s: %.*sxxxxxxx\n", key, 5, strval);
			} else {
				printf("%s: %s\n", key, strval);
			}
			free(strval);
			break;
		}
		case PLIST_BOOLEAN: {
			printf("%s: %s\n", key, (plist_bool_val_is_true(node)) ? "true" : "false");
			break;
		}
		default:
			break;
		}
	} else if (cerr == COMPANION_PROXY_E_TIMEOUT_REPLY) {
		printf("Timeout trying to read value for key '%s'\n", key);
	} else {
		printf("Unexpected error occurred\n");
	}
}

static void handle_signal(int sig)
{
	quit_flag++;
}

static int connected = 0;

static void device_event_cb(const idevice_event_t *event, void *user_data)
{
	char* udid = (char*)user_data;
	if (event->event == IDEVICE_DEVICE_ADD) {
		if (udid) {
			if (!strcmp(udid, event->udid)) {
				connected = 1;
			}
		}
	} else if (event->event == IDEVICE_DEVICE_REMOVE) {
		if (udid) {
			if (!strcmp(udid, event->udid)) {
				connected = 0;
			}
		}
	}
}

int main(int argc, char** argv)
{
	if (argc < 2) {
		printf("usage: comptest UDID\n");
		return -1;
	}
	signal(SIGINT, handle_signal);
	signal(SIGTERM, handle_signal);
#ifndef WIN32
	signal(SIGPIPE, SIG_IGN);
	signal(SIGQUIT, handle_signal);
#endif

	idevice_event_subscribe(device_event_cb, argv[1]);
	printf("Waiting for phone...\n");
	while (!connected && !quit_flag) {
		sleep(1);
	}

	idevice_event_unsubscribe();

	idevice_t device = NULL;
	if (idevice_new_with_options(&device, argv[1], IDEVICE_LOOKUP_USBMUX | IDEVICE_LOOKUP_NETWORK) != IDEVICE_E_SUCCESS || !device) {
		fprintf(stderr, "Could not find device %s\n", argv[1]);
		return -1;
	}

	printf("Connected!\n");

	//idevice_set_debug_level(1);

	printf("Retrieving list of watches...\n");

	companion_proxy_client_t cpx = NULL;
	if (companion_proxy_client_start_service(device, &cpx, NULL) != COMPANION_PROXY_E_SUCCESS || !cpx) {
		fprintf(stderr, "Failed to start companion_proxy\n");
		idevice_free(device);
		return -1;
	}

	plist_t devices = NULL;
	companion_proxy_error_t cerr = companion_proxy_get_device_registry(cpx, &devices);
	companion_proxy_client_free(cpx);
	if (cerr == COMPANION_PROXY_E_SUCCESS) {
		plist_array_iter iter = NULL;
		plist_array_new_iter(devices, &iter);
		plist_t value = NULL;
		do {
			plist_array_next_item(devices, iter, &value);
			if (value) {
				plist_t val = NULL;
				char* watch_udid = NULL;
				plist_get_string_val(value, &watch_udid);	

				printf("Checking watch %s\n", watch_udid);

				get_value_from_watch(device, watch_udid, "DeviceName");

				get_value_from_watch(device, watch_udid, "ProductType");

				get_value_from_watch(device, watch_udid, "SerialNumber");

				get_value_from_watch(device, watch_udid, "BatteryCurrentCapacity");

				get_value_from_watch(device, watch_udid, "BatteryIsCharging");

				free(watch_udid);
			}
		} while (value);
		free(iter);
		plist_free(devices);
	}


	idevice_free(device);

	return 0;
}
