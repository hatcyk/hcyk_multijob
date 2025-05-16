import { isEnvBrowser } from "./misc";

/**
 * Simple wrapper around fetch API tailored for CEF/NUI use. This abstraction
 * can be extended to include AbortController if needed or if the response isn't
 * JSON. Tailor it to your needs.
 *
 * @param eventName - The endpoint eventname to target
 * @param data - Data you wish to send in the NUI Callback
 * @param mockData - Mock data to be returned if in the browser
 *
 * @return returnData - A promise for the data sent back by the NuiCallbacks CB argument
 */

export async function fetchNui<T = unknown>(
  eventName: string,
  data?: unknown,
  mockData?: T,
): Promise<T> {
  const options = {
    method: "post",
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify(data),
  };

  if (isEnvBrowser() && mockData) {
    if (import.meta.env.DEV) {
      console.log(`[fetchNui] Browser environment detected - using mock data for ${eventName}`);
      console.log(`[fetchNui] Mock data:`, mockData);
    }
    return mockData;
  }

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : "nui-frame-app";

  if (import.meta.env.DEV) console.log(`[fetchNui] Sending request to ${resourceName}/${eventName}`, data);
  const resp = await fetch(`https://${resourceName}/${eventName}`, options);

  const respFormatted = await resp.json();
  if (import.meta.env.DEV) console.log(`[fetchNui] Received response from ${eventName}:`, respFormatted);

  return respFormatted;
}
