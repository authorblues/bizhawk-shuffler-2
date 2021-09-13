using System;
using BizHawk.Client.Common;
using BizHawk.Client.EmuHawk;

namespace BizHawkShuffler
{
    public static class APIs
    {
        // hack-ish way to make these APIs available outside of the main tool form

        private static IMainFormForTools? mainForm;
        private static ApiContainer? apiContainer;
        private static IEmuClientApi? clientApi;
        private static IEmulationApi? emulationApi;
        private static IGameInfoApi? gameInfoApi;
        private static ISaveStateApi? saveStateApi;

        public static IMainFormForTools MainForm => Require(mainForm);
        public static ApiContainer ApiContainer => Require(apiContainer);
        // these seem to always be available even when no ROM is loaded
        public static IEmuClientApi Client => Require(clientApi);
        public static IEmulationApi Emulation => Require(emulationApi);
        public static IGameInfoApi GameInfo => Require(gameInfoApi);
        public static ISaveStateApi SaveState => Require(saveStateApi);



        internal static void Update(ApiContainer apiContainer)
        {
            APIs.apiContainer = apiContainer;
            Fill(out clientApi);
            Fill(out emulationApi);
            Fill(out gameInfoApi);
            Fill(out saveStateApi);

            void Fill<T>(out T? field) where T : class, IExternalApi
            {
                if (apiContainer.Libraries.TryGetValue(typeof(T), out var api))
                    field = api as T;
                else
                    field = null;
            }
        }

        internal static void Update(IMainFormForTools mainForm)
        {
            APIs.mainForm = mainForm;
        }

        private static T Require<T>(T? value) where T : class
            => value ??
               throw new InvalidOperationException($"{typeof(T).Name} is not available. Accessed before tool has been initialized?");



        public static bool LoadRom(string path)
        {
            // Copy what the OpenRom API does because `IEmuClientApi.OpenRom` does not return the success bool
            // https://github.com/TASVideos/BizHawk/blob/b8f5050d6c426ba81ec1b1e1265b9b6cb9a40d3a/src/BizHawk.Client.Common/Api/Classes/EmuClientApi.cs#L141
            return MainForm.LoadRom(
                path,
                new() { OpenAdvanced = OpenAdvancedSerializer.ParseWithLegacy(path) }
            );
        }

    }

}
