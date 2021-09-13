using Newtonsoft.Json;

namespace BizHawkShuffler
{
    internal static class Serialization
    {

        private static readonly JsonSerializerSettings Settings = CreateSettings();



        private static JsonSerializerSettings CreateSettings()
        {
            return new JsonSerializerSettings
            {
                Formatting = Formatting.Indented,
                ObjectCreationHandling = ObjectCreationHandling.Auto,
            };
        }

        public static JsonSerializer Serializer { get; } = GetSerializer();

        public static JsonSerializer GetSerializer()
        {
            return JsonSerializer.CreateDefault(Settings);
        }
    }
}
