//非MonoBehaviour类型继承（线程安全）
    /// <summary>
    ///     非MonoBehaviour类型的单件辅助基类，利用C#的语法性质简化单件类的定义和使用
    /// </summary>
    /// <typeparam name="T">单件子类型</typeparam>
    public class Singleton<T> where T : class, new()
    {
        // 单件子类实例
        private static T _instance;

        protected Singleton()
        {
        }

        /// <summary>
        ///     获得类型的单件实例
        /// </summary>
        /// <returns>类型实例</returns>
        public static T Instance()
        {
            if (null == _instance)
            {
                _instance = new T();
            }

            return _instance;
        }

        /// <summary>
        /// 删除单件实例
        /// </summary>
        public static void DestroyInstance()
        {
            _instance = null;
        }
    }