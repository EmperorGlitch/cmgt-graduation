using System.Net;
using System.Net.Sockets;
using System.Linq;

public static class NetworkScanner
{
    public static string GetLocalIpAddress()
    {
        IPHostEntry hostEntry = Dns.GetHostEntry(Dns.GetHostName());
        IPAddress ip = hostEntry.AddressList.FirstOrDefault(ip => ip.AddressFamily == AddressFamily.InterNetwork);

        return ip?.ToString();
    }

    public static string GetLocalSubnet()
    {
        string ip = GetLocalIpAddress();

        if (string.IsNullOrEmpty(ip)) 
            return null;

        string[] ipParts = ip.Split('.');
        return $"{ipParts[0]}.{ipParts[1]}.{ipParts[2]}";
    }
}
